{
  den,
  lib,
  inputs,
  ...
}:
let
  hjemClass = "hjem";
  hjemOsClasses = [
    "nixos"
    "darwin"
  ];

  hostConf =
    { host, ... }:
    {
      options.hjem = {
        enable = lib.mkEnableOption "Enable hjem";
        module = lib.mkOption {
          type = lib.types.deferredModule;
          default = inputs.hjem."${host.class}Modules".default;
        };
      };
    };

  hjemDetect =
    { host }:
    let
      isOsSupported = builtins.elem host.class hjemOsClasses;
      hjemUsers = builtins.filter (u: lib.elem hjemClass u.classes) (lib.attrValues host.users);
      hasHjemUsers = builtins.length hjemUsers > 0;
      isHjemHost = host.hjem.enable && isOsSupported && hasHjemUsers;
    in
    lib.optional isHjemHost { inherit host; };

  ctx.host.into.hjem-host = hjemDetect;

  ctx.hjem-host._.hjem-host =
    { host }:
    {
      ${host.class}.imports = [ host.hjem.module ];
    };

in
{
  den.ctx = ctx;
  den.base.host.imports = [ hostConf ];
}
