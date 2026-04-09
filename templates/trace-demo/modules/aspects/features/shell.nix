{ den, ... }:
{
  den.aspects.shell = {
    homeManager.programs.fish.enable = true;
    homeManager.programs.starship.enable = true;
  };
}
