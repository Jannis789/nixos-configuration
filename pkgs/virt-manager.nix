# pkgs/virt-manager.nix
{ config, pkgs, ... }:

{
  programs.virt-manager.enable = true;

  virtualisation.libvirtd.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  users.users.${config.root-user.userName} = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" ];
  };
}
