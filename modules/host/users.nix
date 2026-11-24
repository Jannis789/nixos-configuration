{ secrets, ... }:
{
  users.users.jannis = {
    isNormalUser = true;
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [ secrets.SSH_KEYS.lannitz.public ];
    extraGroups = [
      "wheel"
      "networkmanager"
      # /dev/uinput für Gamepads: systemd-udev gibt uinput an die
      # Gruppe "input" (0660) — Gamepads erscheinen dadurch als echte
      # Kernel-Geräte, die Steam/Proton ohne Interposer finden. Genutzt
      # von Sunshines uinput-Input (modules/host/sunshine.nix; das NixOS-
      # Modul setzt hardware.uinput.enable) und früher von Selkies.
      "input"
    ];
    linger = true;
  };
  security.sudo.wheelNeedsPassword = false;
}
