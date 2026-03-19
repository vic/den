{
  lib,
  inputs,
  den,
  ...
}:
let
  fa-lib = inputs.flake-aspects.lib lib;
  # In Den all aspects are context forwarders
  defaultFunctor = (den.lib.parametric { }).__functor;
  typesConf = { inherit defaultFunctor; };
  types = lib.mapAttrs (n: v: v typesConf) fa-lib.types;
in
fa-lib // { inherit types; }
