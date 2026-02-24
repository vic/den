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
  hjemModule = host: host.hjem-module or inputs.hjem."${host.class}Modules".default;

  hjemDetect =
    { host }:
    let
      isOsSupported = builtins.elem host.class hjemOsClasses;
      hasHjemModule = (host ? hjem-module) || (inputs ? hjem);
      hjemUsers = builtins.filter (u: lib.elem hjemClass u.classes) (lib.attrValues host.users);
      hasHjemUsers = builtins.length hjemUsers > 0;
      isHjemHost = isOsSupported && hasHjemUsers && hasHjemModule;
    in
    lib.optional isHjemHost { inherit host; };

in
{
  den.ctx.host.into.hjem-host = hjemDetect;

  den.ctx.hjem-host._.hjem-host =
    { host }:
    {
      ${host.class}.imports = [ (hjemModule host) ];
    };
}
