{ inputs, lib, ... }:
let
  has-flake-parts = inputs ? flake-parts;
  outputOptions.flake = lib.mkOption {
    default = { };
    type = lib.types.submodule { freeformType = lib.types.lazyAttrsOf lib.types.unspecified; };
  };
in
{
  options = lib.optionalAttrs (!has-flake-parts) outputOptions;
}
