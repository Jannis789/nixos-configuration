{
  config,
  lib,
  pkgs,
  ...
}:

# SonarQube lokal (Community Build als OCI-Container unter Podman) +
# offizieller SonarQube MCP Server als System-Binary, damit goose (und damit
# heron, das nur `goose acp` startet) per MCP-Extension auf Code-Qualität
# zugreifen kann.
#
# - Server:      http://127.0.0.1:9000 (nur lokal gebindet; Erst-Login admin/admin)
# - MCP-Server:  /run/current-system/sw/bin/sonarqube-mcp (stdio, Java 21)
# - goose-Seite: Extension "sonarqube" in ~/.config/goose/config.yaml
#   (cmd: /run/current-system/sw/bin/sonarqube-mcp, envs: SONARQUBE_URL +
#   SONARQUBE_TOKEN — User-Token nach erstem Login in der SQ-UI erzeugen)
# - 100 % offline: Das Podman-Netz ist --internal (kein Gateway/NAT, kein
#   Internet), SonarQube startet mit sonar.telemetry.enable=false und
#   sonar.updatecenter.activate=false. Der MCP-Server meldet nichts nach
#   außen, weil die Extension TELEMETRY_DISABLED="true" setzt — sonst ruft
#   er https://events.sonardata.io/mcp bei jedem Start/Tool-Call (22.11.
#   mit strace verifiziert; "1" statt "true" wird ignoriert).
# - Update:      Version-Pins (image / version) unten ändern und rebuilden.
#
# Voraussetzungen laut Sonar-Doku: Community Build ≥ 25.1 für den MCP-Server —
# erfüllt durch das gepinnte Image 26.11. Das oci-containers-Backend dieses
# Hosts ist podman (Default in nixpkgs unstable); für Namensauflösung
# sonarqube → sonarqube-db braucht es ein Netzwerk mit aktiviertem
# aardvark-DNS (das Default-Netzwerk hat dns_enabled=false).

let
  # SonarQube MCP Server (github.com/SonarSource/sonarqube-mcp-server) als JAR
  # aus dem offiziellen Binaries-Repo, gepinnt; stdio-Transport braucht Java 21+.
  sonarqube-mcp = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "sonarqube-mcp";
    version = "1.33.0.5260";
    src = pkgs.fetchurl {
      url = "https://binaries.sonarsource.com/Distribution/sonarqube-mcp-server/sonarqube-mcp-server-${finalAttrs.version}.jar";
      hash = "sha256-EFiKHIlVYPxxwrokVhCP8sLWRYP6aaoAvLqGA96dBE0=";
    };
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      runHook preInstall
      install -Dm444 "$src" "$out/share/java/sonarqube-mcp-server.jar"
      makeWrapper "${pkgs.jdk21_headless}/bin/java" "$out/bin/sonarqube-mcp" \
        --add-flags "-jar $out/share/java/sonarqube-mcp-server.jar"
      runHook postInstall
    '';
    meta = {
      description = "SonarQube MCP Server (stdio) für goose/heron";
      mainProgram = "sonarqube-mcp";
    };
  });
in
{
  # MCP-Binary systemweit — goose referenziert es absolut:
  #   cmd: /run/current-system/sw/bin/sonarqube-mcp
  environment.systemPackages = [ sonarqube-mcp ];

  # SonarQubes eingebettetes Elasticsearch verlangt (laut offizieller Doku):
  boot.kernel.sysctl."vm.max_map_count" = 262144;
  boot.kernel.sysctl."fs.file-max" = 131072;

  # Podman-Netzwerk mit DNS, damit sonarqube ↔ sonarqube-db per Namen reden
  systemd.services.podman-sonarnet = {
    description = "Podman network for the SonarQube stack (DNS enabled)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.podman ];
    script = ''
      # 100 % offline: --internal gibt dem Netz KEIN Default-Gateway und kein
      # NAT — die Container können physisch nicht ins Internet (verifiziert:
      # DNS im Netz schlägt fehl). Ein bestehendes Egress-Netz aus früheren
      # Builds wird ersetzt; die Container-Units legen ihre Container danach
      # neu an.
      if ! podman network inspect sonarnet >/dev/null 2>&1; then
        podman network create --internal sonarnet
      elif [ "$(podman network inspect -f '{{.Internal}}' sonarnet)" != "true" ]; then
        podman rm -f sonarqube sonarqube-db >/dev/null 2>&1 || true
        podman network rm -f sonarnet
        podman network create --internal sonarnet
      fi
    '';
  };

  virtualisation.oci-containers.containers = {
    sonarqube-db = {
      # Podman braucht voll-qualifizierte Namen (keine Short-Names ohne
      # containers-registries.conf)
      image = "docker.io/library/postgres:17-alpine";
      environment = {
        POSTGRES_USER = "sonar";
        POSTGRES_PASSWORD = "sonar"; # nur im lokalen Podman-Netz, Eval-Server
        POSTGRES_DB = "sonar";
      };
      volumes = [ "/var/lib/sonarqube/postgres:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=sonarnet" ];
    };
    sonarqube = {
      image = "docker.io/library/sonarqube:26.11.0.134175-community"; # Community Build
      dependsOn = [ "sonarqube-db" ];
      # KEIN ports = mehr: Podman kann auf einem --internal-Netz keine Ports
      # veröffentlichen (verifiziert 22.11.). Der Zugang läuft über den
      # socat-Proxy "sonarqube-proxy" unten, der 127.0.0.1:9000 auf die
      # Container-IP weiterreicht.
      environment = {
        SONAR_JDBC_URL = "jdbc:postgresql://sonarqube-db:5432/sonar";
        SONAR_JDBC_USERNAME = "sonar";
        SONAR_JDBC_PASSWORD = "sonar";
        # 100 % offline: Telemetrie + Update-Center (Plugin-Katalog) aus.
        # SonarQube mappt SONAR_<PROPERTY> auf sonar.<property>.
        SONAR_TELEMETRY_ENABLE = "false";
        SONAR_UPDATECENTER_ACTIVATE = "false";
      };
      volumes = [
        "/var/lib/sonarqube/data:/opt/sonarqube/data"
        "/var/lib/sonarqube/extensions:/opt/sonarqube/extensions"
        "/var/lib/sonarqube/logs:/opt/sonarqube/logs"
      ];
      extraOptions = [ "--network=sonarnet" ];
    };
  };

  # Ingress für das interne Netz: Podman veröffentlicht auf --internal-Netzen
  # keine Ports, der Host erreicht die Container-IP aber direkt. socat
  # reicht 127.0.0.1:9000 dorthin — nach außen bleibt der Container dicht.
  # Die IP wird bei jedem Start neu gelesen (Restart-Loop), weil Podman sie
  # nach einem Neuanlegen des Containers ändern kann.
  systemd.services.sonarqube-proxy = {
    description = "TCP-Proxy 127.0.0.1:9000 → SonarQube (internes Podman-Netz)";
    after = [ "podman-sonarqube.service" ];
    requires = [ "podman-sonarqube.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.podman
      pkgs.socat
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 2;
    };
    script = ''
      while :; do
        ip=$(podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' sonarqube 2>/dev/null)
        if [ -n "$ip" ]; then
          socat TCP-LISTEN:9000,bind=127.0.0.1,fork,reuseaddr "TCP:$ip:9000" || true
        fi
        sleep 2
      done
    '';
  };

  # Eigenes Loop-Volume für /opt/sonarqube/data (40 GB, sparse):
  # SonarQubes EsDiskSpaceChecker ist HARDCODED auf "10 % des Daten-Volumes
  # frei, max 150 GB" (server/sonar-main/.../EsDiskSpaceChecker.java) — auf
  # der 907-GB-Root-Partition wären also ~91 GB frei nötig. Auf dem eigenen
  # kleinen Volume sind es nur 4 GB. root_owner=1000:1000 passt die Rechte
  # für den im Container laufenden SonarQube-User direkt beim mkfs an.
  systemd.services.sonarqube-es-volume = {
    description = "Sparse loop image for SonarQube data (ES disk-space check)";
    # DefaultDependencies aus und KEIN wantedBy: Der Dienst wird ausschließlich
    # über x-systemd.requires= vom Mount gezogen. Mit Default-Dependencies
    # (after sysinit.target) entstünde ein Zyklus
    # local-fs.target → var-lib-sonarqube-data.mount → dieser Dienst → sysinit.target.
    before = [ "var-lib-sonarqube-data.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      pkgs.e2fsprogs
      pkgs.util-linux
    ];
    script = ''
      IMG=/var/lib/sonarqube/data.img
      if [ ! -s "$IMG" ]; then
        truncate -s 40G "$IMG"
        mkfs.ext4 -F -E root_owner=1000:1000 -L sonarqube-data "$IMG"
      fi
    '';
  };

  fileSystems."/var/lib/sonarqube/data" = {
    device = "/var/lib/sonarqube/data.img";
    fsType = "ext4";
    options = [
      "loop"
      "x-systemd.requires=sonarqube-es-volume.service"
    ];
  };

  # Netzwerk + Daten-Volume vor den Containern aufziehen (das
  # oci-containers-Modul setzt für Podman-Units bereits TimeoutStartSec=0,
  # lange Image-Pulls brechen also nicht ab).
  systemd.services."podman-sonarqube-db" = {
    after = [ "podman-sonarnet.service" ];
    wants = [ "podman-sonarnet.service" ];
  };
  systemd.services."podman-sonarqube" = {
    after = [
      "podman-sonarnet.service"
      "var-lib-sonarqube-data.mount"
    ];
    wants = [
      "podman-sonarnet.service"
      "var-lib-sonarqube-data.mount"
    ];
  };

  # Host-Verzeichnisse für die Container-Volumes
  # (SonarQube läuft im Container als uid 1000; postgres chown't selbst).
  systemd.tmpfiles.rules = [
    "d /var/lib/sonarqube 0755 root root - -"
    "d /var/lib/sonarqube/postgres 0700 root root - -"
    "d /var/lib/sonarqube/data 0755 1000 1000 - -"
    "d /var/lib/sonarqube/extensions 0755 1000 1000 - -"
    "d /var/lib/sonarqube/logs 0755 1000 1000 - -"
  ];
}
