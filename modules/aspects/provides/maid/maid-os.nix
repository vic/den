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

  maidClass = "maid";
  maidOsClasses = [ "nixos" ];

  ctx.host.into.maid-host = detectHost {
    className = maidClass;
    supportedOses = maidOsClasses;
    optionPath = "nix-maid";
  };

  ctx.maid-host._.maid-host =
    { host }:
    {
      ${host.class}.imports = [ host.nix-maid.module ];
    };

  hostConf = hostOptions {
    className = maidClass;
    optionPath = "nix-maid";
    inputsPath = "nix-maid";
    getModule = { host, ... }: inputs.nix-maid.nixosModules.default;
  };

in
{
  den.ctx = ctx;
  den.schema.host.imports = [ hostConf ];
}
