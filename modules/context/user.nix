{ den, lib, ... }:
let
  inherit (den.lib) take;
  inherit (den.lib.parametric) fixedTo atLeast;

  ctx.user.description = ''
    ## Context: den.ctx.user{host,user}

    User context stage is produced by Host for each user.

    This is a **continuation** of the pipeline started by `den.ctx.host`.

    IMPORTANT: The configuration obtained from `den.ctx.user` is provided to the Host OS level

    In Den, home-manager/hjem/maid are just forwarding classes that produce config at the OS
    level: `home-manager.users.<alice>`, `hjem.users.<alice>`, `users.users.<alice>`, etc.

    A `den.ctx.user{host,user}` transitions unconditionally into `den.ctx.default{host,user}`

    A `den.ctx.user{host,user}` obtains OS configuration nixos/darwin by using `fixedTo{host,user} user-aspect`.
    fixedTo takes:
      -  user-aspect's owned attrs
      -  static includes like { nixos.foo = ... } or ({ class, aspect-chain }: { nixos.foo = ...; })
      -  atLeast{host,user} parametric includes like ({ host,user }: { nixos.foo = ...; })

  '';

  ctx.user.into.default = lib.singleton;
  ctx.user.provides.user = take.exactly from-user;

  from-user = { host, user }: fixedTo { inherit host user; } user.aspect;

in
{
  den.ctx = ctx;
}
