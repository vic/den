{
  inputs,
  lib,
  config,
  ...
}:
let
  types = import ./_types.nix { inherit inputs lib config; };
in
{
  options.den.hosts = types.hostsOption;
  options.den.homes = types.homesOption;
  config._module.args.den = config.den;
}
