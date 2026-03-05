{
  den,
  lib,
  inputs,
  ...
}:
let
  inherit (den.lib.home-env)
    intoClassUsers
    forwardToHost
    ;

  hjemClass = "hjem";

  ctx.hjem-host.into.hjem-user = intoClassUsers hjemClass;
  ctx.hjem-user._.hjem-user = forwardToHost {
    className = hjemClass;
    forwardPathFn =
      { user, ... }:
      [
        "hjem"
        "users"
        user.userName
      ];
  };
in
{
  den.ctx = ctx;
}
