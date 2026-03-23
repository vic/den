{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (config) den;
  types = import ./../nix/lib/types.nix {
    inherit
      inputs
      lib
      den
      config
      ;
  };
  schemaOption = lib.mkOption {
    description = "freeform deferred modules per entity kind";
    default = { };
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf lib.types.deferredModule;
    };
  };
in
{
  options.den.hosts = types.hostsOption;
  options.den.homes = types.homesOption;
  options.den.schema = schemaOption;
  config.den.schema = {
    conf = { };
    host.imports = [ den.schema.conf ];
    user.imports = [ den.schema.conf ];
    home.imports = [ den.schema.conf ];
  };
}
