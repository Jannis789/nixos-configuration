{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    wget
    git
    starship
    atuin
    zoxide
    nix-bash-completions
    blesh
    nixfmt-rfc-style
    git-credential-manager
    openssh
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
  ];

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "blackbox";
  };

  programs.nvf = {
    enable = true;
    settings = {
      vim.viAlias = false;
      vim.vimAlias = true;
      vim.lsp = {
        enable = true;
      };
      vim.theme = {
        enable = true;
        name = "catppuccin";
        style = "mocha";
      };
    };
  };
}
