{ pkgs, ... }:

{
  environment = {
    gnome.excludePackages = with pkgs; [
      gnome-music
      gnome-tour
      gnome-logs
      geary
      totem
      epiphany
      firefox
      gnome-system-monitor
    ];

    systemPackages = with pkgs; [
      btop
      fastfetch
      git
      wget
      starship
      atuin
      zoxide
      nix-bash-completions
      blesh
      nixfmt
      git-credential-manager
      opencode
      ollama
      ollama-rocm
      ollama-vulkan
      openssh
      wl-clipboard
      unzip
      tree
      fzf
      joplin

      vim
      bun
      nodejs
      deno
      sqlite
      antares
      ghostty
      python3

      firefox
      vesktop
      vscode.fhs
      fragments
      gnome-tweaks
      dconf-editor
      mission-center
      clapper
      keeweb
      joplin-desktop
      rewaita-custom
      helium

      protonplus
      steam
      mangohud
      protonup-ng
      gamescope
      libdecor

      spice-vdagent
      vulkan-tools
      mesa-demos
      networkmanager-openvpn
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
  ];

  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
        protontricks
        mangohud
      ];
    };

    gamemode.enable = true;
  };
}
