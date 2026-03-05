{
  den,
  lib,
  inputs,
  ...
}:
let
  atPath = path: obj: lib.foldr (key: obj: obj.${key} or { }) obj path;

  host-has-user-with-class =
    host: class:
    lib.pipe host.users [
      (lib.attrValues)
      (map (user: lib.elem class user.classes))
      (lib.filter lib.id)
      (xs: lib.length xs > 0)
    ];

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
      classUsers = builtins.filter (u: lib.elem className u.classes) (lib.attrValues host.users);
      hasClassUsers = builtins.length classUsers > 0;
      getOption = atPath (lib.splitString "." optionPath);
      isEnabled = (getOption host).enable or false;
      shouldActivate = isEnabled && isOsSupported && hasClassUsers;
    in
    lib.optional shouldActivate { inherit host; };

  hostOptions =
    {
      className,
      optionPath,
      inputsPath,
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

  forwardToHost =
    {
      className,
      forwardPathFn,
      aspectFn ? null,
    }:
    { host, user }:
    let
      aspect = if aspectFn != null then aspectFn { inherit host user; } else den.aspects.${user.aspect};
    in
    den._.forward {
      each = lib.singleton true;
      fromClass = _: className;
      intoClass = _: host.class;
      intoPath = _: forwardPathFn { inherit host user; };
      fromAspect = _: aspect;
    };

in
{
  inherit
    detectHost
    hostOptions
    intoClassUsers
    forwardToHost
    ;
}
