{
  den,
  lib,
  inputs,
  ...
}:
let
  inherit (den.lib.home-env)
    detectHost
    hostOptions
    ;

  hmClass = "homeManager";
  hmOsClasses = [
    "nixos"
    "darwin"
  ];

  ctx.host.into.hm-host = detectHost {
    className = hmClass;
    supportedOses = hmOsClasses;
    optionPath = "home-manager";
  };

  ctx.hm-host.provides.hm-host =
    { host }:
    {
      ${host.class}.imports = [ host.home-manager.module ];
    };

  hostConf = hostOptions {
    className = hmClass;
    optionPath = "home-manager";
    inputsPath = "home-manager";
    getModule = { host, ... }: inputs.home-manager."${host.class}Modules".home-manager;
  };

in
{
  den.ctx = ctx;
  den.schema.host.imports = [ hostConf ];
}
