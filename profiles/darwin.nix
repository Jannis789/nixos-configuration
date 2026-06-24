{ config, lib, pkgs, ... }:

{
  # ── System-Options ──────────────────────────────────────────────────────
  options.system = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "jrustige";
    };
    homeStateVersion = lib.mkOption {
      type = lib.types.str;
      default = "25.05";
    };
  };

  config = {
    # ── Nix ────────────────────────────────────────────────────────────────
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # ── System-Version ─────────────────────────────────────────────────────
    system.stateVersion = 7;

    # ── User (wichtig: home-manager liest users.users.<name>.home) ──────
    users.users.${config.system.userName} = {
      home = "/Users/${config.system.userName}";
    };
  };
}
