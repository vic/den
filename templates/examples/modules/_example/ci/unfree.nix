{ den, ... }:
{
  # cam uses unfree vscode.
  den.aspects.cam.homeManager.programs.vscode.enable = true;
  den.aspects.cam.includes = [ (den._.unfree [ "vscode" ]) ];
}
