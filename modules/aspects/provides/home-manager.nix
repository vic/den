{
  den,
  lib,
  inputs,
  ...
}:
let
  inherit (den.lib.home-env) makeHomeEnv;

  result = makeHomeEnv {
    className = "homeManager";
    ctxName = "hm";
    optionPath = "home-manager";
    getModule = { host, ... }: inputs.home-manager."${host.class}Modules".home-manager;
    forwardPathFn =
      { user, ... }:
      [
        "home-manager"
        "users"
        user.userName
      ];
  };

  homeCtx = {
    home.provides.home = { home }: den.lib.parametric.fixedTo { inherit home; } home.aspect;
    home.into.default = lib.singleton;
  };
in
{
  den.ctx = result.ctx // homeCtx;
  den.schema.host.imports = [ result.hostConf ];
  den.schema.aspect.options.homeManager = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
  };
}
