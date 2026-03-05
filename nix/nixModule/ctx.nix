{ config, lib, ... }:
let
  inherit (config) den;
  inherit (den.lib.aspects.types) aspectSubmodule;
  inherit (den.lib) ctxApply;

  # a context-definiton is an aspect extended with into.* transformations
  # and a fixed functor to apply them.
  ctxSubmodule = lib.types.submodule (
    { config, ... }:
    {
      imports = aspectSubmodule.getSubModules;
      options.into = lib.mkOption {
        description = "Context transformations to other context types";
        type = lib.types.lazyAttrsOf (lib.types.functionTo (lib.types.listOf lib.types.raw));
        default = { };
      };
      config.__functor = lib.mkForce ctxApply;
    }
  );

in
{
  options.den.ctx = lib.mkOption {
    default = { };
    type = lib.types.lazyAttrsOf ctxSubmodule;
  };
}
