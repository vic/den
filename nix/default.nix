let
  flakeModules.default = ./flakeModule.nix;
  flakeModules.dendritic = ./dendritic.nix;
in
{
  flakeModule = flakeModules.default;
  inherit flakeModules;
  modules.flake = flakeModules;
  templates = {
    default.path = ../templates/default;
    default.description = "Batteries included";
    minimal.path = ../templates/minimal;
    minimal.description = "Minimalistic den";
    examples.path = ../templates/examples;
    examples.description = "API examples and CI";
    bogus.path = ../templates/bogus;
    bogus.description = "For bug reproduction";
  };
  packages = import ./template-packages.nix;
  namespace = import ./namespace.nix;
  lib = import ./lib.nix;
}
