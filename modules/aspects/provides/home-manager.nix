{
  den,
  lib,
  inputs,
  ...
}:
let
  inherit (den.lib.home-env) makeHomeEnv;

  hm-aspect-deprecated = ''
    NOTICE: den.provides.home-manager aspect is not used anymore.
    See https://den.oeiuwq.com/guides/home-manager/

    Since den.ctx.hm-host requires least one user with homeManager class,
    Home Manager is now enabled via options.

    For all users unless they set a value:

       den.schema.user.classes = lib.mkDefault [ "homeManager" ];

    On specific users:

       den.hosts.x86_64-linux.igloo.users.tux.classes = [ "homeManager" ];

    For attaching aspects to home-manager enabled hosts.
  '';

  result = makeHomeEnv {
    className = "homeManager";
    ctxName = "hm";
    optionPath = "home-manager";
    inputsPath = "home-manager";
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
    home.provides.home =
      { home }: den.lib.parametric.fixedTo { inherit home; } den.aspects.${home.aspect};
    home.into.default = lib.singleton;
  };

in
{
  den.provides.home-manager = _: throw hm-aspect-deprecated;
  den.ctx = result.ctx // homeCtx;
  den.schema.host.imports = [ result.hostConf ];
}
