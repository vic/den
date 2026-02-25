let
  flakeModules.default = ./flakeModule.nix;
  flakeModules.dendritic = ./dendritic.nix;
in
{
  # for non-flakes, our default modules needs no flakes
  nixModule = flakeModules.default;

  # flake-parts conventions
  flakeModule = flakeModules.default;
  inherit flakeModules;
  modules.flake = flakeModules;

  templates = {
    default.path = ../templates/default;
    default.description = "Default template";
    minimal.path = ../templates/minimal;
    minimal.description = "Minimalistic den";
    noflake.path = ../templates/noflake;
    noflake.description = "Den without flake";
    example.path = ../templates/example;
    example.description = "Example";
    ci.path = ../templates/ci;
    ci.description = "Feature Tests";
    bogus.path = ../templates/bogus;
    bogus.description = "For bug reproduction";
  };
  packages = import ./flake-packages.nix;
  namespace = import ./namespace.nix;
  lib = import ./lib.nix;
}
