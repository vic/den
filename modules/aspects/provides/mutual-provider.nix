# See usage at: templates/example/modules/aspects/{defaults.nix,alice.nix,igloo.nix}
{ den, ... }:
let
  inherit (den.lib) take parametric;

  description = ''
    Allows hosts and users to contribute configuration **to each other** 
    through `provides`.

    This battery implements an aspect "routing" pattern.

    This is not the same as `den._.bidirectional` battery, but provides a
    **safer** alternative to `den._.bidirectional`.
    The reason is that this battery does not re-invoke the `host-aspect.includes`,
    instead it relies on you defining provides.

    Unlike `den.default` which is `parametric.atLeast` we use
    `parametric.fixedTo` here, which help us propagate an already computed
    context to all includes.

    This battery, when installed in a `parametric.atLeast` will just forward
    the same context.  The `find-mutual` helper returns an static configuration
    which is ignored by parametric aspects, thus allowing non-existing
    aspects to be just ignored.

    Be sure to read diagrams for the Host context pipeline:
    https://den.oeiuwq.com/guides/bidirectional

    ## Usage

      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.default.includes = [ den._.mutual-provider ];

      # user aspect provides to specific host or to all where it lives
      den.aspects.tux = {
        provides.igloo.nixos.programs.emacs.enable = true;
        provides.to-hosts = { host, ... }: {
          nixos.programs.nh.enable = host.name == "igloo";
        };
      };

      # host aspect provides to specific user or to all its users
      den.aspects.igloo = {
        provides.alice.homeManager.programs.vim.enable = true;
        provides.to-users = { user, ... }: {
          homeManager.programs.helix.enable = user.name == "alice";
        };
      };
  '';

  find-mutual = from: to: den.aspects.${from.aspect}._.${to.aspect} or { };
  user-to-hosts = user: den.aspects.${user.aspect}._.to-hosts or { };
  host-to-users = host: den.aspects.${host.aspect}._.to-users or { };

in
{
  den.provides.mutual-provider = take.exactly (
    { host, user }@ctx:
    parametric.fixedTo ctx {
      inherit description;
      includes = [
        (find-mutual host user)
        (find-mutual user host)
        (host-to-users host)
        (user-to-hosts user)
      ];
    }
  );
}
