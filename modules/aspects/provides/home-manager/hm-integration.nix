{
  inputs,
  lib,
  den,
  ...
}:
let
  inherit (den.lib) parametric;

  description = ''
    integrates home-manager into nixos/darwin OS classes.

    Does nothing for hosts that have no users with `homeManager` class.
    Expects `inputs.home-manager` to exist. If `<host>.hm-module` exists
    it is the home-manager.{nixos/darwin}Modules.home-manager.

    For each user produces a `den.ctx.hm` context, and
    forwards the `homeManager` class into os-level
    `home-manager.home-manager.users.<user>`
  '';

  hmClass = "homeManager";

  intoHmUsers =
    { host }:
    map (user: { inherit host user; }) (
      lib.filter (u: lib.elem hmClass u.classes) (lib.attrValues host.users)
    );

  forwardedToHost =
    { host, user }:
    den._.forward {
      each = lib.singleton true;
      fromClass = _: hmClass;
      intoClass = _: host.class;
      intoPath = _: [
        "home-manager"
        "users"
        user.userName
      ];
      fromAspect = _: (den.ctx.hm-internal-user { inherit host user; });
    };

in
{
  den.provides.home-manager = { };

  den.ctx.home.description = "Standalone Home-Manager config provided by home aspect";
  den.ctx.home._.home = { home }: parametric.fixedTo { inherit home; } den.aspects.${home.aspect};
  den.ctx.home.into.default = lib.singleton;

  den.ctx.hm-host.into.hm-user = intoHmUsers;
  den.ctx.hm-user.description = "(internal)";
  den.ctx.hm-user._.hm-user = forwardedToHost;

  den.ctx.hm-internal-user._.hm-internal-user =
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
}
