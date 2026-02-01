{ inputs, lib, ... }:
{
  # we can import this flakeModule even if we dont
  # have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  # for flake.nixosConfigurations output.
  # create a freeform option for it
  options.flake = lib.mkOption {
    type = lib.types.submodule { freeformType = lib.types.anything; };
  };
}
