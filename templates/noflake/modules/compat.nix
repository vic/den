{ inputs, lib, ... }:
{
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  # NOTE: Currently Den needs a top-level attribute where to place configurations,
  # by default it is the `flake` attribute, even if Den uses no flake-parts at all.
  options.flake = lib.mkOption {
    type = lib.types.submodule { freeformType = lib.types.anything; };
  };
}
