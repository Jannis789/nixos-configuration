{ config, lib, pkgs, inputs, ... }:

{
  networking.hostName = "jannis";
  programs.nix-ld.enable = true;

  imports = [
    ../../modules/nixos/hermes-agent.nix
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      vulkan-loader
      vulkan-tools
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      vulkan-loader
    ];
  };

  services.gnome.gnome-remote-desktop.enable = true;

  systemd.services.gnome-remote-desktop = {
    wantedBy = [ "graphical.target" ];
  };

  # Wake-on-LAN für enp6s0 aktivieren
  networking.interfaces.enp6s0.wakeOnLan.enable = true;

  # Service setzt WoL beim Boot und nochmal beim Shutdown (ExecStop),
  # weil manche Treiber die Einstellung beim Herunterfahren verlieren.
  systemd.services.wake-on-lan = {
    description = "Enable WoL on enp6s0";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp6s0 wol g";
      ExecStop = "${pkgs.ethtool}/bin/ethtool -s enp6s0 wol g";
    };
  };

  environment.systemPackages = with pkgs; [ ethtool sunshine hermes-desktop ];

  # SSH — Port 4422 (22 ist oft von FritzBox blockiert)
  services.openssh = {
    enable = true;
    ports = [ 22 4422 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.jannis.openssh.authorizedKeys.keyFiles = [
    "${inputs.secrets}/ssh-authorized-keys"
  ];

  # Sunshine (Game Streaming für Moonlight) — User-Service für Display-Zugriff
  users.users.jannis.linger = true;

  systemd.user.services.sunshine = {
    description = "Sunshine Game Streaming Server";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Sunshine Ports — Bereiche statt Einzelports
  #   TCP 47984-47990: Web UI + RTSP-Setup
  #   TCP 48010:       RTSP-Stream
  #   UDP 47998-48002: Steuerung + Audio + Mikrofon
  networking.firewall.allowedTCPPorts = [ 22 4422 3389 48010 ];
  networking.firewall.allowedTCPPortRanges = [ { from = 47984; to = 47990; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 47998; to = 48002; } ];
}
