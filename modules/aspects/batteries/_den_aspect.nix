mk-aspect:
# deadnix: skip
{
  lib,
  inputs,
  den,
  config,
  ...
}@args:
let
  aspect = mk-aspect args;
  aspect-option = import ../_aspect_option.nix { inherit inputs lib; };
in
{
  config.den.${aspect.name} = aspect;
  options.den.${aspect.name} = aspect-option aspect.description;
}
