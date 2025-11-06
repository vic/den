{ lib, inputs, ... }:
let
  den-lib = inputs.target.lib lib inputs;
  inherit (den-lib) parametric;

  flake.tests."test foo" =
    let
      inherit (den-lib.dependencies den) hostAspect;

      den.default.__functor = parametric true;
      den.default.nixos.foo = 1;
      den.default.includes = [];

      host.aspect = "host";
      host.class = "nixos";

      den.aspects = {
        host = aspect;
      };
      aspect = (hostAspect host den).host // {
        nixos.owned = 0;
      };

      arg = {
        class = host.class;
        aspect-chain = [ ];
      };

      result = aspect arg;

      expr = {
        first-include-is-owned = ((lib.head result.includes) arg).nixos;
        includes-length = lib.length result.includes;
      };
      expected = {
        first-include-is-owned = aspect.nixos;
        includes-length = 1;
      };
    in
    { 
      break = builtins.break expr;
      inherit expr expected; 
    };

in
{
  inherit flake;
}
