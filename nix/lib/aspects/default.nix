{
  lib,
  den,
  ...
}:
let
  defaultFunctor = (den.lib.parametric { }).__functor;
  typesConf = { inherit defaultFunctor; };
  rawTypes = import ./types.nix lib;
  types = lib.mapAttrs (_: v: v typesConf) rawTypes;
  resolve = import ./resolve.nix lib;
in
{
  inherit types resolve;
}
