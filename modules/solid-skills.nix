{
  solidSkills,
  ...
}:

# solid-skills (github.com/ramziddin/solid-skills): Agent-Skill im
# Claude-kompatiblen SKILL.md-Format (SOLID, TDD, Clean Code, Design Patterns).
# goose entdeckt globale Skills beim Session-Start in ~/.agents/skills —
# heron profitiert automatisch, weil es nur `goose acp` startet (kein
# Hardcoding im heron-Projekt). Quelle ist der Flake-Input (Commit-Pin in
# flake.lock), nicht ein lokaler Clone.
#
# Nutzung in heron/goose: Skill wird bei passenden Aufgaben automatisch
# geladen oder explizit per `/skills solid`.
{
  home.file.".agents/skills/solid".source = "${solidSkills}/skills/solid";
}
