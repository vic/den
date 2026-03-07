# See usage at: templates/example/modules/aspects/{defaults.nix,alice.nix,igloo.nix}
{ den, ... }:
let
  description = ''
    Allows specifically-chosen hosts and users to contribute configuration **to
    each other** through `provides`.

    This is not the same as the built-in bidirectionality:

      # contributes to ALL users of this host
      den.aspects.my-host.homeManager = { ... }

      # contributes to ALL hosts of where my-user exist
      den.aspects.my-user.nixos = { ... }

    The difference is that this allows you to wire bidirectionality between
    explictly-named hosts/users pairs (see the usage below).

    This battery implements an aspect "routing" pattern.

    Unlike `den.default` which is `parametric.atLeast` we use
    `parametric.fixedTo` here, which help us propagate an already computed
    context to all includes.

    This battery, when installed in a `parametric.atLeast` will just forward
    the same context.  The `mutual` helper returns an static configuration
    which is ignored by parametric aspects, thus allowing non-existing
    aspects to be just ignored.

    Be sure to read the Host Context section on:
    https://den.oeiuwq.com/explanation/context-pipeline

    ## Usage

      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.default.includes = [ den._.bidirectional-provider ];

    A user providing config TO the host:

      den.aspects.tux = {
        provides.igloo = { host, ... }: {
          nixos.programs.nh.enable = host.name == "igloo";
        };
      };

    A host providing config TO the user:

      den.aspects.igloo = {
        provides.tux = { user, ... }: {
          homeManager.programs.helix.enable = user.name == "alice";
        };
      };
  '';

  mutual = from: to: den.aspects.${from.aspect}._.${to.aspect} or { };
in
{
  den.provides.bidirectional-provider =
    { host, user }@ctx:
    den.lib.parametric.fixedTo ctx {
      inherit description;
      includes = [
        (mutual user host)
        (mutual host user)
      ];
    };
}
