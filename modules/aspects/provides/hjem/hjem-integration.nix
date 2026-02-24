{ den, lib, ... }:
let
  hjemClass = "hjem";

  intoHjemUsers =
    { host }:
    map (user: { inherit host user; }) (
      lib.filter (u: lib.elem hjemClass u.classes) (lib.attrValues host.users)
    );

  forwardedToHost =
    { host, user }:
    den._.forward {
      each = lib.singleton true;
      fromClass = _: hjemClass;
      intoClass = _: host.class;
      intoPath = _: [
        "hjem"
        "users"
        user.userName
      ];
      fromAspect = _: den.aspects.${user.aspect};
    };

in
{
  den.ctx.hjem-host.into.hjem-user = intoHjemUsers;
  den.ctx.hjem-user._.hjem-user = forwardedToHost;
}
