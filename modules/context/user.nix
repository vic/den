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

    ## Bidirectionality

    Battery `den.provides.bidirectional` can be included on each user that needs to take configuration from the Host.

    Enable per user:
       den.aspects.tux.includes = [ den._.bidirectional ];

    Enable for all users:
       den.ctx.user.includes = [ den._.bidirectional ];

    IMPORTANT: Enabling bidirectionality means that the following piepline is enabled:

       host-aspect{host} => user-aspect{host,user} => host-aspect{host,user}

    This means that any function at host-aspect.includes can be called:
      - once when the host is obtaining its own configuration with context {host}
      - once PER user that has bidirectionality enabled with context {host,user}

    Because of this, parametric aspects at host-aspect must be careful

       Instead of  -in Nix both of these have the same functionArgs-

         ({host}: ...) 

       or 

         ({host, ...}: ...)

       Do this to prevent the function being invoked with `{host,user}`

          take.exactly ({host}: ...)

       Or this to avoid it being invoked with `{host}`

          take.atLeast ({host,user}: ...)

    Static aspects, -functions  like `{class,aspect-chain}: ...`- at host-aspect.includes
    have **no way** to distinguish when the calling context is `{host}` or `{host,user}` if
    bidirectionality is enabled.

    Because of this, if you have such functions, they might produce duplicate values on list or
    conflicting values on package types. A work around is to wrap them in a context-aware function:

       take.exactly ({host}: { includes = [ ({class, aspect-chain}: ...) ]; })

  '';

  ctx.user.into.default = lib.singleton;
  ctx.user.provides.user = take.exactly from-user;
  ctx.user.provides.bidirectional = take.exactly from-host;

  from-user = { host, user }: fixedTo { inherit host user; } den.aspects.${user.aspect};
  from-host = { host, user }: atLeast den.aspects.${host.aspect} { inherit host user; };
in
{
  den.ctx = ctx;
}
