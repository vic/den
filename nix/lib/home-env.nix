{
  den,
  lib,
  inputs,
  ...
}:
let
  atPath = path: obj: lib.attrByPath path { } obj;

  host-has-user-with-class =
    host: class: builtins.any (user: lib.elem class user.classes) (lib.attrValues host.users);

  detectHost =
    {
      className,
      supportedOses ? [
        "nixos"
        "darwin"
      ],
      optionPath,
    }:
    { host }:
    let
      isOsSupported = builtins.elem host.class supportedOses;
      isEnabled = (atPath (lib.splitString "." optionPath) host).enable or false;
      shouldActivate = isEnabled && isOsSupported && host-has-user-with-class host className;
    in
    lib.optional shouldActivate { inherit host; };

  hostOptions =
    {
      className,
      optionPath,
      getModule,
    }:
    { host, ... }:
    {
      options.${optionPath} = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = host-has-user-with-class host className;
        };
        module = lib.mkOption {
          type = lib.types.deferredModule;
          default = getModule { inherit host inputs; };
        };
      };
    };

  intoClassUsers =
    className:
    { host }:
    map (user: { inherit host user; }) (
      lib.filter (u: lib.elem className u.classes) (lib.attrValues host.users)
    );

  userEnvAspect =
    ctxName:
    { host, user }:
    { class, aspect-chain }:
    {
      includes = [
        (den.ctx."${ctxName}-user" { inherit host user; })
        (den.ctx.user { inherit host user; })
      ];
    };

  forwardToHost =
    {
      className,
      ctxName,
      forwardPathFn,
    }:
    { host, user }:
    den._.forward {
      each = lib.singleton true;
      fromClass = _: className;
      intoClass = _: host.class;
      intoPath = _: forwardPathFn { inherit host user; };
      fromAspect = _: userEnvAspect ctxName { inherit host user; };
    };

  makeHomeEnv =
    {
      className,
      ctxName ? className,
      supportedOses ? [
        "nixos"
        "darwin"
      ],
      optionPath,
      getModule,
      forwardPathFn,
    }:
    {
      ctx = {
        host.into."${ctxName}-host" = detectHost { inherit className supportedOses optionPath; };

        "${ctxName}-host" = {
          provides."${ctxName}-host" =
            { host }:
            {
              ${host.class}.imports = [ host.${optionPath}.module ];
            };
          into."${ctxName}-user" = intoClassUsers className;
        };

        "${ctxName}-user".provides."${ctxName}-user" = forwardToHost {
          inherit className ctxName forwardPathFn;
        };
      };

      hostConf = hostOptions {
        inherit
          className
          optionPath
          getModule
          ;
      };
    };

in
{
  inherit makeHomeEnv;
}
