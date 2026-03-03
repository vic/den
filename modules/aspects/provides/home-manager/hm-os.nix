{
  den,
  lib,
  inputs,
  ...
}:
let
  description = ''
    Detects hosts that have an HM supported OS and
    that have at least one user with ${hm-class} class.

    When this occurs it produces a context `den.ctx.hm-host`

    This `den.ctx.hm-os` context includes the OS-level
    homeManager module and is used by hm-integration.nix to then
    produce a `den.ctx.hm-user` for each user.

    This same context can be used to include aspects
    ONLY for hosts having HM enabled.

       den.ctx.hm-host.includes = [ den.aspects.foo ];
  '';

  hm-class = "homeManager";
  hm-os-classes = [
    "nixos"
    "darwin"
  ];

  hostConf =
    { host, ... }:
    {
      options.home-manager = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = den.lib.host-has-user-with-class host hm-class;
        };
        module = lib.mkOption {
          type = lib.types.deferredModule;
          default = inputs.home-manager."${host.class}Modules".home-manager;
        };
      };
    };

  hm-detect =
    { host }:
    let
      is-os-supported = builtins.elem host.class hm-os-classes;
      hm-users = builtins.filter (u: lib.elem hm-class u.classes) (lib.attrValues host.users);
      has-hm-users = builtins.length hm-users > 0;
      is-hm-host = host.home-manager.enable && is-os-supported && has-hm-users;
    in
    lib.optional is-hm-host { inherit host; };

  ctx.host.into.hm-host = hm-detect;

  ctx.hm-host.description = description;
  ctx.hm-host.provides.hm-host =
    { host }:
    {
      ${host.class}.imports = [ host.home-manager.module ];
    };

in
{
  den.ctx = ctx;
  den.base.host.imports = [ hostConf ];
}
