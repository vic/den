{
  inputs,
  lib,
  config,
  ...
}:
inputs.flake-aspects.lib.newAspects lib (option: modules: {
  options.den.aspects = option;
  options.den.modules = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.deferredModule);
    default = modules;
  };
}) config.den.aspects
