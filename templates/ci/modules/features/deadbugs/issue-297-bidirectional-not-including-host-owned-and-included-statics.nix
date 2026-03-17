{ denTest, ... }:
{
  flake.tests.deadbugs-issue-297 = {

    test-bidirectional-host-owned = denTest (
      {
        den,
        lib,
        igloo, # igloo = nixosConfigurations.igloo.config
        tuxHm, # tuxHm = igloo.home-manager.users.tux
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux.classes = [ "homeManager" ];
        den.ctx.user.includes = [ den._.bidirectional ];

        den.aspects.igloo.homeManager.home.keyboard.model = "denkbd";

        expr = tuxHm.home.keyboard.model;
        expected = "denkbd";
      }
    );

    test-bidirectional-host-included-statics = denTest (
      {
        den,
        lib,
        igloo, # igloo = nixosConfigurations.igloo.config
        tuxHm, # tuxHm = igloo.home-manager.users.tux
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux.classes = [ "homeManager" ];
        den.ctx.user.includes = [ den._.bidirectional ];

        den.aspects.base.homeManager.home.keyboard.model = "denkbd";
        den.aspects.igloo.includes = [ den.aspects.base ];

        expr = tuxHm.home.keyboard.model;
        expected = "denkbd";
      }
    );

    test-bidirectional-host-owned-home-option = denTest (
      {
        den,
        lib,
        igloo, # igloo = nixosConfigurations.igloo.config
        tuxHm, # tuxHm = igloo.home-manager.users.tux
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux.classes = [ "homeManager" ];
        den.ctx.user.includes = [ den._.bidirectional ];

        den.aspects.igloo.homeManager.options.foo = lib.mkOption { default = "foo"; };

        expr = tuxHm.foo;
        expected = "foo";
      }
    );

    test-bidirectional-host-owned-host-option = denTest (
      {
        den,
        lib,
        igloo, # igloo = nixosConfigurations.igloo.config
        tuxHm, # tuxHm = igloo.home-manager.users.tux
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux.classes = [ "homeManager" ];
        den.ctx.user.includes = [ den._.bidirectional ];

        # NOTE: this causes an error: Option already defined!
        # This is because bidirectionality includes host configs again.
        # den.aspects.igloo.nixos.options.foo = lib.mkOption { default = "foo"; };
        # NOTE: Under bidirectionality, use perHost
        den.aspects.igloo.includes = [
          (den.lib.perHost {
            nixos.options.foo = lib.mkOption { default = "foo"; };
          })
        ];

        expr = igloo.foo;
        expected = "foo";
      }
    );

  };
}
