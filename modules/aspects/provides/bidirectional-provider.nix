# See usage at: defaults.nix, alice.nix, igloo.nix
{ den, ... }:
{
  den.provides.bidirectional-provider =
    { host, user }@ctx:
    den.lib.parametric.fixedTo ctx {
      description = ''
        Allows hosts and users to contribute configuration **to each other**
        through `provides`.

        This battery implements an aspect "routing" pattern.

        Unlike `den.default` which is `parametric.atLeast` we use
        `parametric.fixedTo` here, which help us propagate an already computed
        context to all includes.

        This battery, when installed in a `parametric.atLeast` will just forward
        the same context.  The `mutual` helper returns an static configuration
        which is ignored by parametric aspects, thus allowing non-existing
        aspects to be just ignored.

        Be sure to read: https://vic.github.io/den/dependencies.html

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

      includes =
        let
          mutual = from: to: den.aspects.${from.aspect}._.${to.aspect} or { };
        in
        [
          (mutual user host)
          (mutual host user)
        ];
    };
}
