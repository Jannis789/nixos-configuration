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
  # Zweiter Account NUR fuer den Stream (headless GNOME-Session).
  # Grund: pro UID gibt es genau einen "systemd --user" und ein dconf.
  # Solange der Stream im jannis-Manager laeuft, erben ueber systemd
  # gestartete Apps dessen Environment (WAYLAND_DISPLAY=wayland-0) und
  # landen auf dem physischen Schreibtisch. Ein eigener User bekommt
  # eigenen Manager, eigenen Session-Bus, eigenes dconf/PermissionStore.
  # Linger: der Manager startet beim Boot, ohne Login.
  users.users.virtual-jannis = {
    isNormalUser = true;
    description = "Stream-Session (Headless GNOME)";
    home = "/home/virtual-jannis";
    initialPassword = "changeme";
    extraGroups = [
      # /dev/dri/renderD128 ist 0666, aber video/render schadet nicht:
      # mutter-headless braucht den Render-Node fuer EGL/DMA-BUF.
      "video"
      "render"
      # /dev/uinput + /dev/input/event* (0660) fuer Gamepads aus
      # Sunshines libvirtualhid-Pfad.
      "input"
    ];
    linger = true;
  };

  security.sudo.wheelNeedsPassword = false;
}
