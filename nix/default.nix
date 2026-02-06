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
    default.description = "Default template";
    minimal.path = ../templates/minimal;
    minimal.description = "Minimalistic den";
    example.path = ../templates/example;
    example.description = "Example";
    ci.path = ../templates/ci;
    ci.description = "Feature Tests";
    bogus.path = ../templates/bogus;
    bogus.description = "For bug reproduction";
  };
  packages = import ./template-packages.nix;
  namespace = import ./namespace.nix;
  lib = import ./lib.nix;
}
