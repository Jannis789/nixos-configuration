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

  # Secrets als User-Env (systemd environment.d): pi + GUI-Prozesse sehen
  # die API-Keys aus /run/secrets (deployt vom activationScript). Kein
  # Store-Leak, Keys landen nur im /run/secrets (root-only).
  systemd.user.sessionVariables = { };
  home.file.".config/environment.d/secrets.conf".text = ''
    # API-Keys aus /run/secrets (activationScript, lazy + Submodule)
    . /run/secrets/api-keys 2>/dev/null || true
    unset API_SERVER_KEY 2>/dev/null || true
  '';

  # Bash: Keys auch in interaktiven Shells (pi CLI aus Terminal)
  programs.bash.bashrcExtra = ''
    if [ -f /run/secrets/api-keys ]; then
      set -a
      . /run/secrets/api-keys
      set +a
      unset API_SERVER_KEY 2>/dev/null || true
    fi
  '';
}
