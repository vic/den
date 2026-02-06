{ den, ... }:

let
  codeAspect = {
    includes = [ (den._.unfree [ "vscode" ]) ];
    homeManager.programs.vscode.enable = true;
  };
  discordAspect = {
    includes = [
      (den._.unfree [ "discord" ])
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.discord ];
      };
  };
in
{
  # cam uses unfree vscode and discord loaded from different aspects.
  den.aspects.cam.includes = [
    codeAspect
    discordAspect
  ];
}
