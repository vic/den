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

    IMPORTANT: Enabling bidirectionality means that the following pipeline is enabled:

       host-aspect{host} => user-aspect{host,user} => host-aspect{host,user}

    Notice that the host-aspect is being activated more than once!

    This means that host configurations are obtained
      - once when the host is obtaining its own configuration with context {host}
      - once PER user that has bidirectionality enabled with context {host,user}

    Due to Nix `lib.functionArgs` not distinguishing between `{host}` and `{host, ...}`,
    Den provides these utilities built upon `den.lib.take.exactly`:

          # Do this to prevent being invoked with `{host,user}`
          den.lib.perHost ({host}: ...)

          # Do this to prevent being invoked with `{host}`
          den.lib.perUser ({host,user}: ...)

    Static aspects (plain-attrsets) or host-owned classes at a Host-aspect
    have **no way** to distinguish when the calling context is 
    `{host}` or `{host,user}`, only functions are context-aware.

    Because of this, a host-aspect might produce duplicate values on list,
    package types, or unique values like options:

          # lists, packages and options need to be unique.
          # this line would produce duplicate errors IF bidirectional enabled
          den.aspects.igloo.nixos.options.foo = lib.mkOption {};

          # Instead, wrap in perHost things that must be unique
          den.aspects.igloo.includes = [
             (den.lib.perHost { nixos.options.foo = lib.mkOption {}; })
          ]
  '';

  ctx.user.into.default = lib.singleton;
  ctx.user.provides.user = take.exactly from-user;
  ctx.user.provides.bidirectional = take.exactly from-host;

  from-user = { host, user }: fixedTo { inherit host user; } den.aspects.${user.aspect};

  from-host = { host, user }: fixedTo { inherit host user; } den.aspects.${host.aspect};

in
{
  den.ctx = ctx;
}
