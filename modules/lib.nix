{
  lib,
  inputs,
  config,
  ...
}:
let
  # "Just Give 'Em One of These" -  Moe Szyslak
  funk = import ../nix/aspect-functor.nix lib;

  parametric =
    param: aspect:
    if param == true then
      funk aspect
    else
      # deadnix: skip
      { class, aspect-chain }: funk aspect param;

  aspects = inputs.flake-aspects.lib lib;
in
{
  config.den.lib = {
    inherit parametric aspects;
  };
  options.den.lib = lib.mkOption {
    readOnly = true;
    internal = true;
    visible = false;
    type = lib.types.attrsOf lib.types.raw;
  };
}
