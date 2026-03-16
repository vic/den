{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (config) den;
  types = import ./../nix/lib/types.nix { inherit inputs lib den; };
  baseMod = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
  };
in
{
  options.den.hosts = types.hostsOption;
  options.den.homes = types.homesOption;
  options.den.schema = {
    conf = baseMod;
    host = baseMod;
    user = baseMod;
    home = baseMod;
  };
  config.den.schema = {
    host.imports = [ den.schema.conf ];
    user.imports = [ den.schema.conf ];
    home.imports = [ den.schema.conf ];
  };
}
