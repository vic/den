{ den, lib, ... }:
let
  inherit (den.lib.parametric) fixedTo atLeast;

  ctx.host.desc = "OS";
  ctx.host.conf = { host }: fixedTo { inherit host; } den.aspects.${host.aspect};

  ctx.host.into.default = lib.singleton;
  ctx.host.into.user = { host }: map (user: { inherit host user; }) (lib.attrValues host.users);

  ctx.user.desc = "OS user";
  ctx.user.conf =
    { host, user }@ctx:
    {
      includes =
        let
          hostAspect = den.aspects.${host.aspect};
          userAspect = den.aspects.${user.aspect};
        in
        [
          (fixedTo ctx userAspect)
          (atLeast hostAspect ctx)
        ];
    };

  ctx.user.into.default = lib.singleton;

in
{
  config.den.ctx = ctx;
}
