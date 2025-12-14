{
  inputs,
  lib,
  config,
  ...
}:
let
  types = import ./_types.nix { inherit inputs lib config; };
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
    host.imports = [ config.den.base.conf ];
    user.imports = [ config.den.base.conf ];
    home.imports = [ config.den.base.conf ];
  };
}
