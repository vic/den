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

  maidClass = "maid";

  ctx.maid-host.into.maid-user = intoClassUsers maidClass;
  ctx.maid-user._.maid-user = forwardToHost {
    className = maidClass;
    forwardPathFn =
      { user, ... }:
      [
        "users"
        "users"
        user.userName
        "maid"
      ];
  };

in
{
  den.ctx = ctx;
}
