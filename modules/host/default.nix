{
  imports = [
    ./boot.nix
    ./network.nix
    ./users.nix
    ./desktop.nix
    ./editor.nix
    ./gaming.nix
    ./remote-desktop.nix
    ./sunshine.nix
    # Selkies deaktiviert (2026-11-24): kann keine adaptive Auflösung und
    # belegt dieselbe einzige RemoteDesktop-Session von mutter wie Sunshine.
    # ./selkies.nix
    ./cockpit.nix
    ./authelia.nix
    ./nginx.nix
    ./acme-ddns.nix
    ./agenix.nix
    ./compatibility.nix
    ./nix-settings.nix
    ./sonarqube.nix
  ];
}
