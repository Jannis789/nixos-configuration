{ pkgs, ... }:
{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  home.stateVersion = "26.05";

  # pi-coding-agent: damit du mit mir schreiben kannst
  home.packages = with pkgs; [
    pi-coding-agent
    git
  ];

  programs.bash.enable = true;
  programs.git.enable = true;

  # Secrets direkt beim Build importieren (Submodule). Werte landen in der
  # HM-Generation — pi sieht sie als env vars. Bewusst kein activationScript
  # /run/secrets-Dance mehr.
  home.sessionVariables = import ../../secrets/api-keys.nix;
}
