{
  lib,
  ...
}:
{
  options.den.fxPipeline = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use effects-based resolution pipeline (experimental). Optional nix-effects flake input.";
  };
}
