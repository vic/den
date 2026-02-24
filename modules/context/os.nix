{ den, lib, ... }:
let
  inherit (den.lib.parametric) fixedTo atLeast;

  ctx.host.description = "OS";
  ctx.host._.host = { host }: fixedTo { inherit host; } den.aspects.${host.aspect};
  ctx.host._.user =
    { host, user }@ctx:
    {
      includes = [ (atLeast den.aspects.${host.aspect} ctx) ];
    };

  ctx.host.into.default = lib.singleton;
  ctx.host.into.user = { host }: map (user: { inherit host user; }) (lib.attrValues host.users);

  ctx.user.description = "OS user";
  ctx.user._.user =
    { host, user }@ctx:
    {
      includes = [ (fixedTo ctx den.aspects.${user.aspect}) ];
    };

  ctx.user.into.default = lib.singleton;

in
{
  config.den.ctx = ctx;
}
