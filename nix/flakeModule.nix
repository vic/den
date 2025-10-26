{ inputs, lib, ... }:
let
  types = import ./types.nix { inherit inputs lib; };
in
{
  imports = [
    ./config.nix
    ./aspects.nix
  ];
  options.den.hosts = types.hostsOption;
  options.den.homes = types.homesOption;
}
