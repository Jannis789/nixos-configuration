{ inputs }:
final: prev:

let
  patchedJediLanguageServer = prev.python313Packages.jedi-language-server.overrideAttrs (old: {
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail 'jedi>=0.19.2,<0.20' 'jedi>=0.19.2'
    '';
  });
in
{
  rewaita-custom = prev.callPackage ./etc/custom_pkgs/rewaita-custom.nix { };
  helium = prev.callPackage ./etc/custom_pkgs/helium.nix { };

  python313Packages = prev.python313Packages.overrideScope (pyFinal: pyPrev: {
    jedi-language-server = patchedJediLanguageServer;
  });

  vscode-extensions = prev.vscode-extensions // {
    ms-python = prev.vscode-extensions.ms-python // {
      python = prev.vscode-extensions.ms-python.python.overrideAttrs (old: {
        propagatedBuildInputs =
          builtins.map
            (dep:
              if dep.name == "python3.13-jedi-language-server-0.46.0" then
                patchedJediLanguageServer
              else
                dep
            )
            old.propagatedBuildInputs;
      });
    };
  };
}
