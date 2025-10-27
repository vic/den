{
  inputs,
  lib,
  config,
  ...
}:
let
  types = import ./types.nix { inherit inputs lib config; };
in
{
  imports = [
    ./scope.nix
    ./config.nix
    ./aspects.nix
  ];
  options.den.hosts = types.hostsOption;
  options.den.homes = types.homesOption;
  config._module.args.den = config.den;
}
