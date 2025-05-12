{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    blesh
    btop
    fastfetch
    wget
    git
    starship
    atuin
    zoxide
    nix-bash-completions
    nixfmt-rfc-style
    git-credential-manager
    openssh
    wl-clipboard
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
  ];

  programs.bash = {
    completion.enable = true;
  };

  programs.nvf = {
    enable = true;

    settings = {
      vim = {

        extraPackages = with pkgs; [
          wl-clipboard
        ];

        lsp = {
          enable = true;
        };

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        useSystemClipboard = true;

        options = {
          guifont = "FiraCode Nerd Font Medium:h12";
          termguicolors = true;
          undofile = true;
          smartindent = true;
          tabstop = 2;
          shiftwidth = 2;
          shiftround = true;
          expandtab = true;
          cursorline = true;
          textwidth = 80;
          wrap = true;
          linebreak = true;
          relativenumber = true;
          number = true;
          viminfo = "";
          viminfofile = "NONE";
          clipboard = "unnamedplus";
          splitright = true;
          splitbelow = true;
          laststatus = 0;
          cmdheight = 1;
        };

        languages = {
          enableLSP = true;
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          bash.enable = true;
          clang.enable = true;
          css.enable = true;
          dart.enable = true;
          go.enable = true;
          haskell.enable = true;
          hcl.enable = true;
          html.enable = true;
          java.enable = true;
          kotlin.enable = true;
          lua.enable = true;
          markdown.enable = true;
          nix.enable = true;
          python.enable = true;
          ruby.enable = true;
          rust.enable = true;
          scala.enable = true;
          sql.enable = true;
          typst.enable = true;
          ts.enable = true;
          terraform.enable = true;
          yaml.enable = true;
          zig.enable = true;
        };

        filetree = {
          nvimTree = {
            enable = true;
            openOnSetup = true;
          };
        };

        keymaps = [];
      };
    };
  };
}
