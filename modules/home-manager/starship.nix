{ config, lib, ... }:

let
  profiles = {
    default = {
      format = ''
        [░▒▓](#a3aed2)[ 󱄅 ](bg:#a3aed2 fg:#090c0c)[](bg:#7c9bdb fg:#a3aed2)$directory[](fg:#7c9bdb bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$nodejs$rust$golang$php[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)
        $character
      '';

      directory = {
        style = "fg:#e3e5e5 bg:#7c9bdb";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };
      };

      git_branch = {
        symbol = " ";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#7c9bdb bg:#394260)]($style)";
      };

      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#7c9bdb bg:#394260)]($style)";
      };

      nodejs = {
        symbol = " ";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#7c9bdb bg:#212736)]($style)";
      };

      rust = {
        symbol = " ";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#7c9bdb bg:#212736)]($style)";
      };

      golang = {
        symbol = " ";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#7c9bdb bg:#212736)]($style)";
      };

      php = {
        symbol = " ";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#7c9bdb bg:#212736)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:#1d2230";
        format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
      };
    };

    nix-standard = {
      add_newline = true;
      command_timeout = 1300;
      scan_timeout = 50;
      format = "$all$nix_shell$nodejs$lua$golang$rust$php$git_branch$git_commit$git_state$git_status\n$username$hostname$directory";
      character = {
        success_symbol = "[ ](bold green) ";
        error_symbol = "[✗](bold red) ";
      };
    };
  };

  profileName = config.starship.profile;
in
{
  options.starship.profile = lib.mkOption {
    type = lib.types.str;
    default = "default";
  };

  config.programs.starship = {
    enable = true;
    settings = profiles.${profileName};
  };
}
