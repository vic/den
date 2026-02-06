{ inputs, lib, ... }:
if inputs ? flake-parts then
  { }
else
  {
    # NOTE: Currently Den needs a top-level attribute where to place configurations,
    # by default it is the `flake` attribute, even if Den uses no flake-parts at all.
    options.flake = lib.mkOption {
      type = lib.types.submodule { freeformType = lib.types.anything; };
    };
  }
