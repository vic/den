{ den, lib, ... }:
let
  maidClass = "maid";

  intoMaidUsers =
    { host }:
    map (user: { inherit host user; }) (
      lib.filter (u: lib.elem maidClass u.classes) (lib.attrValues host.users)
    );

  forwardedToHost =
    { host, user }:
    den._.forward {
      each = lib.singleton true;
      fromClass = _: maidClass;
      intoClass = _: host.class;
      intoPath = _: [
        "users"
        "users"
        user.userName
        "maid"
      ];
      fromAspect = _: den.aspects.${user.aspect};
    };

in
{
  den.ctx.maid-host.into.maid-user = intoMaidUsers;
  den.ctx.maid-user._.maid-user = forwardedToHost;
}
