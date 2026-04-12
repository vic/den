{
  lib,
  den,
  ...
}:
let
  rawTypes = import ./types.nix { inherit den lib; };
  adapters = import ./adapters.nix { inherit den lib; };
  resolve = import ./resolve.nix { inherit den lib; };
  hasAspect = import ./has-aspect.nix { inherit den lib; };

  defaultFunctor = (den.lib.parametric { }).__functor;
  typesConf = { inherit defaultFunctor; };
  types = lib.mapAttrs (_: v: v typesConf) rawTypes;
in
{
  inherit types adapters resolve;
  inherit (hasAspect) hasAspectIn collectPathSet mkEntityHasAspect;
  mkAspectsType = cnf': lib.mapAttrs (_: v: v (typesConf // cnf')) rawTypes;
}
