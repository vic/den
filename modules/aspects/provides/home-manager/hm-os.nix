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
      ${host.class} = {
        imports = [ host.home-manager.module ];
        # Prevent the home-manager manual.nix module from eagerly evaluating
        # nixosOptionsDoc (which creates an options.json derivation referencing
        # the nixpkgs source store path without proper string context).
        # Users can re-enable with mkForce if they need HM manpages.
        home-manager.sharedModules = [
          {
            manual.manpages.enable = lib.mkDefault false;
          }
        ];
      };
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
