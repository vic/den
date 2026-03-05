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

  hjemClass = "hjem";
  hjemOsClasses = [
    "nixos"
    "darwin"
  ];

  ctx.host.into.hjem-host = detectHost {
    className = hjemClass;
    supportedOses = hjemOsClasses;
    optionPath = "hjem";
  };

  ctx.hjem-host._.hjem-host =
    { host }:
    {
      ${host.class}.imports = [ host.hjem.module ];
    };

  hostConf = hostOptions {
    className = hjemClass;
    optionPath = "hjem";
    inputsPath = "hjem";
    getModule = { host, ... }: inputs.hjem."${host.class}Modules".default;
  };
in
{
  den.ctx = ctx;
  den.base.host.imports = [ hostConf ];
}
