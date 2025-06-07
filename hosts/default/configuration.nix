# hosts/default/configuration.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../users/root-user.nix
    ../../pkgs/gtk.nix
    ../../pkgs/cli.nix
    ../../pkgs/grub.nix
    ../../pkgs/game.nix
    ../../pkgs/flatpak.nix
    ../../pkgs/virt-manager.nix
    ../../pkgs/etc.nix
    ../../overlays/gdm-colors/package.nix
    inputs.home-manager.nixosModules.default
    inputs.nixvim.nixosModules.nixvim
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
    LC_MESSAGES = "de_DE.UTF-8";
  };

  services.xserver.enable = true;

  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  console.keyMap = "de";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.spice-vdagentd.enable = true;

  root-user.enable = true;
  root-user.userName = "jannis";
  root-user.userPassword = "Jannis21";

  users.users."jannis".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFfq2ljLyzRX+kVATeeqR3KGOpo9ECOhTvkUN58FoZ/A jrustige@wonko"
  ];

  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users = {
      "jannis" = import ./home.nix;
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    EDITOR = "nvim";
    XDG_ICONS_PATH = "${pkgs.hicolor-icon-theme}/share:${pkgs.adwaita-icon-theme}/share";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.11";

  programs.bash.blesh.enable = true;
}
