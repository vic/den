# Smoke tests for entity.hasAspect — the core functionality:
# host/user/home all have the method, and the bare form works for
# structurally-present aspects. The full regression-class test matrix
# (Groups A–I per design spec §7.3) lands in a follow-up commit.
#
# Note: `igloo` from denTest specialArgs is the resolved NixOS config
# (config.flake.nixosConfigurations.igloo.config), not the den host
# entity. The host entity — which is where `hasAspect` lives — is
# reached via `den.hosts.x86_64-linux.igloo`. Same for users:
# `den.hosts.x86_64-linux.igloo.users.tux`.
{ denTest, lib, ... }:
{
  flake.tests.has-aspect = {

    test-host-hasAspect-present-static = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [ den.aspects.feature ];
        den.aspects.feature.nixos = { };

        # host.hasAspect is available because host imports
        # den.schema.conf which imports modules/context/has-aspect.nix.
        expr = den.hosts.x86_64-linux.igloo.hasAspect den.aspects.feature;
        expected = true;
      }
    );

    test-host-hasAspect-absent = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.nixos = { };
        den.aspects.unrelated.nixos = { };

        expr = den.hosts.x86_64-linux.igloo.hasAspect den.aspects.unrelated;
        expected = false;
      }
    );

    test-user-hasAspect-present = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        # denTest's default is classes = ["homeManager"] for users.
        den.aspects.tux.includes = [ den.aspects.user-feature ];
        den.aspects.user-feature.homeManager = { };

        expr = den.hosts.x86_64-linux.igloo.users.tux.hasAspect den.aspects.user-feature;
        expected = true;
      }
    );

    test-hasAspect-forClass-explicit = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [ den.aspects.feature ];
        den.aspects.feature.nixos = { };

        expr = den.hosts.x86_64-linux.igloo.hasAspect.forClass "nixos" den.aspects.feature;
        expected = true;
      }
    );

    test-hasAspect-forAnyClass = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [ den.aspects.feature ];
        den.aspects.feature.nixos = { };

        expr = den.hosts.x86_64-linux.igloo.hasAspect.forAnyClass den.aspects.feature;
        expected = true;
      }
    );

    test-hasAspect-respects-tombstone = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [
          den.aspects.keep
          den.aspects.drop
        ];
        den.aspects.igloo.meta.adapter =
          inherited: den.lib.aspects.adapters.excludeAspect den.aspects.drop inherited;
        den.aspects.keep.nixos = { };
        den.aspects.drop.nixos = { };

        expr = {
          keep = den.hosts.x86_64-linux.igloo.hasAspect den.aspects.keep;
          drop = den.hosts.x86_64-linux.igloo.hasAspect den.aspects.drop;
        };
        expected = {
          keep = true;
          drop = false;
        };
      }
    );

    test-hasAspect-angle-bracket-equivalent = denTest (
      { den, __findFile, ... }:
      {
        _module.args.__findFile = den.lib.__findFile;

        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.feature.nixos = { };
        den.aspects.igloo.includes = [ den.aspects.feature ];

        # <feature> sugar resolves to den.aspects.feature via __findFile.
        expr = {
          viaAttr = den.hosts.x86_64-linux.igloo.hasAspect den.aspects.feature;
          viaAngle = den.hosts.x86_64-linux.igloo.hasAspect <feature>;
        };
        expected = {
          viaAttr = true;
          viaAngle = true;
        };
      }
    );

  };
}
