{ den, lib, ... }:
let
  ctx.host.description = ''
    ## Context: den.ctx.host{host}

    Host context stage configures an OS

    A {host} context fan-outs into many {host,user} contexts.

    A `den.ctx.host{host}` transitions unconditionally into `den.ctx.default{host}`

    A `den.ctx.host{host}` obtains OS configuration nixos/darwin by using `fixedTo{host} host-aspect`.
    fixedTo takes:
      -  host-aspect's owned attrs
      -  static includes like { nixos.foo = ... } or ({ class, aspect-chain }: { nixos.foo = ...; })
      -  atLeast{host} parametric includes like ({ host }: { nixos.foo = ...; })
  '';

  ctx.host.into.user = { host }: map (user: { inherit host user; }) (lib.attrValues host.users);
  ctx.host.into.default = lib.singleton;
  ctx.host.provides.host = { host }: host.aspect;

in
{
  den.ctx = ctx;
}
