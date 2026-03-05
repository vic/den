{
  inputs,
  lib,
  den,
  ...
}:
let
  inherit (den.lib.home-env)
    intoClassUsers
    forwardToHost
    ;

  inherit (den.lib) parametric;

  hmClass = "homeManager";

  hm-aspect-deprecated = ''
    NOTICE: den.provides.home-manager aspect is not used anymore.
    See https://den.oeiuwq.com/guides/home-manager/

    Since den.ctx.hm-host requires least one user with homeManager class,
    Home Manager is now enabled via options.

    For all users unless they set a value:

       den.base.user.classes = lib.mkDefault [ "homeManager" ];

    On specific users:

       den.hosts.x86_64-linux.igloo.users.tux.classes = [ "homeManager" ];

    See <den/home-manager/hm-os.nix>

    If you had includes at den._.home-manager, you can use:

       den.ctx.hm-host.includes = [ ... ];

    For attaching aspects to home-manager enabled hosts.
  '';

  ctx.home.provides.home = { home }: parametric.fixedTo { inherit home; } den.aspects.${home.aspect};
  ctx.home.into.default = lib.singleton;

  ctx.hm-host.into.hm-user = intoClassUsers hmClass;
  ctx.hm-user.provides.hm-user = forwardToHost {
    className = hmClass;
    forwardPathFn =
      { user, ... }:
      [
        "home-manager"
        "users"
        user.userName
      ];
    aspectFn = den.ctx.hm-user-internal;
  };

  ctx.hm-user-internal.provides.hm-user-internal =
    { host, user }:
    { class, aspect-chain }:
    {
      includes = [
        (den.ctx.user { inherit host user; })
        (den.lib.owned den.aspects.${host.aspect})
        (den.lib.statics den.aspects.${host.aspect} { inherit class aspect-chain; })
        (parametric.atLeast den.aspects.${host.aspect} { inherit host user; })
      ];
    };
in
{
  den.provides.home-manager = _: throw hm-aspect-deprecated;
  den.ctx = ctx;
}
