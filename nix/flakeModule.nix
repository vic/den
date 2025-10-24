{ lib, ... }:
let
  types = import ./types.nix lib;
in
{
  imports = [
    ./os-config.nix
    ./home-config.nix
    ./aspects-config.nix
  ];
  options.den.hosts = types.hostsOption;
  options.den.homes = types.homesOption;
}
