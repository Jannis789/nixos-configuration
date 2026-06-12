{ config, lib, pkgs, ... }:

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

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.jannis.openssh.authorizedKeys.keyFiles = [
    ../../secrets/ssh-authorized-keys
  ];

  networking.firewall.allowedTCPPorts = [ 3389 22 ];
}
