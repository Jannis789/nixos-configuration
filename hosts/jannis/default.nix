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

  networking.firewall.allowedTCPPorts = [ 3389 22 4422 ];
}
