{ config, pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "de";
        variant = "";
      };
    };

    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    printing.enable = true;
    openssh.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    spice-vdagentd.enable = true;
    libinput.enable = true;
  };
}
