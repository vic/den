{ inputs, lib, ... }:
let
  message = ''
    If you see this message it likely means you have more than
    one value for a flake output and no flake.* option has been
    declared for it, thus the Nix module system does not know
    how to merge both values.

    Add the following in your project, create a module like:

      ```nix
      # modules/output.nix
      { lib, ... }: {
        options.flake.darwinConfigurations = lib.mkOption {
          default = { };
          type = lib.types.lazyAttrsOf lib.types.raw;
        };
      }
      ```

    Add `homeConfigurations` or any other output attribute
    that might need merge-semantics for multiple values.

    See also flake-parts related error messaage: 
    https://github.com/hercules-ci/flake-parts/blob/main/modules/flake.nix
  '';

  has-flake-parts = inputs ? flake-parts;

  outputOptions.flake = lib.mkOption {
    default = { };
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf flakeOutput;
    };
  };

  flakeOutput = uniqueOutput lib.types.unspecified;
  uniqueOutput = lib.types.unique { inherit message; };

in
{
  options = lib.optionalAttrs (!has-flake-parts) outputOptions;
}
