# See usage at: templates/example/modules/aspects/{defaults.nix,alice.nix,igloo.nix}
{ den, ... }:
let
  inherit (den.lib) take parametric;

  description = ''
    Allows hosts and users to contribute configuration **to each other** 
    through `provides`.

    This battery implements an aspect "routing" pattern.

    Be sure to read diagrams for the Host context pipeline:
    https://den.oeiuwq.com/guides/mutual

    ## Usage

      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.ctx.user.includes = [ den._.mutual-provider ];

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
  user-to-users = user: den.aspects.${user.aspect}._.to-users or { };

  mutual-user-user = host: user: {
    includes = map (
      from:
      parametric.fixedTo { inherit host user; } {
        includes = [
          (find-mutual from user)
          (user-to-users from)
        ];
      }
    ) (builtins.filter (u: u != user) (builtins.attrValues host.users));
  };

  mutual-host-user =
    { host, user }:
    parametric.fixedTo { inherit host user; } {
      inherit description;
      includes = [
        (find-mutual host user)
        (find-mutual user host)
        (host-to-users host)
        (user-to-hosts user)
        (mutual-user-user host user)
      ];
    };

  mutual-standalone-home =
    { home }:
    parametric.fixedTo { inherit home; } (
      if home.hostName == null then { } else den.aspects.${home.aspect}._.${home.hostName} or { }
    );

in
{
  den.provides.mutual-provider = parametric.exactly {
    includes = [
      mutual-host-user
      mutual-standalone-home
    ];
  };
}
