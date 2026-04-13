{
  lib,
  ...
}:
{
  options.den.fxPipeline = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Use effects-based resolution pipeline (experimental). Requires nix-effects as a flake input.";
  };
}
