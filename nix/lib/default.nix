{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (config) den;
  load =
    f:
    import f {
      inherit
        lib
        config
        inputs
        den
        den-lib
        ;
    };
  den-lib = builtins.mapAttrs (_: load) {
    aspects = ./aspects;
    canTake = ./can-take.nix;
    ctxApply = ./ctx-apply.nix;
    ctxTypes = ./ctx-types.nix;
    __findFile = ./den-brackets.nix;
    forward = ./forward.nix;
    home-env = ./home-env.nix;
    nh = ./nh.nix;
    nixModule = ../nixModule;
    nsTypes = ./namespace-types.nix;
    parametric = ./parametric.nix;
    statics = ./statics.nix;
    take = ./take.nix;
    lastFunctionTo = ./last-function-to.nix;
    withSubAspectsOf = ./with-sub-aspects-of.nix;
  };
in
den-lib
