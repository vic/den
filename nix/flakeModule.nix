{ lib, ... }:
let
  types = import ./types.nix lib;
in
{
  imports = [
    ./os-config.nix
    ./aspects-config.nix
  ];
  options.den.hosts = types.hostsOption;
}
