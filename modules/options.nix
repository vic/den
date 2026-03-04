{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (config) den;
  types = import ./../nix/types.nix { inherit inputs lib den; };
  baseMod = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
  };
in
{
  options.den.hosts = types.hostsOption;
  options.den.homes = types.homesOption;
  options.den.base = {
    conf = baseMod;
    host = baseMod;
    user = baseMod;
    home = baseMod;
  };
  config.den.base = {
    host.imports = [ den.base.conf ];
    user.imports = [ den.base.conf ];
    home.imports = [ den.base.conf ];
  };
}
