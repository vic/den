# Tests for den.lib.aspects.adapters.oneOfAspects — the structural-
# decision adapter for "prefer A over B when both are present".
{ denTest, lib, ... }:
{
  flake.tests.one-of-aspects = {

    test-prefers-first-present = denTest (
      { den, trace, ... }:
      {
  den.fxPipeline = false;
        den.aspects.bundle.includes = [
          den.aspects.pref-a
          den.aspects.pref-b
        ];
        den.aspects.bundle.meta.adapter = den.lib.aspects.adapters.oneOfAspects [
          den.aspects.pref-a
          den.aspects.pref-b
        ];
        den.aspects.pref-a.nixos = { };
        den.aspects.pref-b.nixos = { };

        # Tombstone visible in trace as ~pref-b.
        expr = trace "nixos" den.aspects.bundle;
        expected.trace = [
          "bundle"
          [ "pref-a" ]
          [ "~pref-b" ]
        ];
      }
    );

    test-falls-through-to-second = denTest (
      { den, trace, ... }:
      {
  den.fxPipeline = false;
        den.aspects.bundle.includes = [ den.aspects.only-b ];
        den.aspects.bundle.meta.adapter = den.lib.aspects.adapters.oneOfAspects [
          den.aspects.pref-a
          den.aspects.only-b
        ];
        # pref-a is defined but not included in the bundle subtree.
        den.aspects.pref-a.nixos = { };
        den.aspects.only-b.nixos = { };

        expr = trace "nixos" den.aspects.bundle;
        expected.trace = [
          "bundle"
          [ "only-b" ]
        ];
      }
    );

    test-both-absent-no-effect = denTest (
      { den, trace, ... }:
      {
  den.fxPipeline = false;
        den.aspects.bundle.includes = [ den.aspects.neither ];
        den.aspects.bundle.meta.adapter = den.lib.aspects.adapters.oneOfAspects [
          den.aspects.pref-a
          den.aspects.pref-b
        ];
        den.aspects.neither.nixos = { };
        # pref-a and pref-b are defined but not included:
        den.aspects.pref-a.nixos = { };
        den.aspects.pref-b.nixos = { };

        # No tombstones — neither candidate is in the subtree.
        expr = trace "nixos" den.aspects.bundle;
        expected.trace = [
          "bundle"
          [ "neither" ]
        ];
      }
    );

    test-composes-with-outer-adapter = denTest (
      { den, trace, ... }:
      {
  den.fxPipeline = false;
        # root sibling-filters bundle and sibling; bundle internally
        # uses oneOfAspects. Verifies the two adapters both take effect
        # at their own level without interfering: root's filter kills
        # the sibling, bundle's oneOfAspects kills pref-b.
        den.aspects.root.includes = [
          den.aspects.bundle
          den.aspects.sibling
        ];
        den.aspects.root.meta.adapter =
          inherited: den.lib.aspects.adapters.excludeAspect den.aspects.sibling inherited;
        den.aspects.bundle.includes = [
          den.aspects.pref-a
          den.aspects.pref-b
        ];
        den.aspects.bundle.meta.adapter = den.lib.aspects.adapters.oneOfAspects [
          den.aspects.pref-a
          den.aspects.pref-b
        ];
        den.aspects.pref-a.nixos = { };
        den.aspects.pref-b.nixos = { };
        den.aspects.sibling.nixos = { };

        expr = trace "nixos" den.aspects.root;
        expected.trace = [
          "root"
          [
            "bundle"
            [ "pref-a" ]
            [ "~pref-b" ]
          ]
          [ "~sibling" ]
        ];
      }
    );

    test-works-on-sub-aspects = denTest (
      { den, trace, ... }:
      {
  den.fxPipeline = false;
        den.aspects.bundle.includes = [
          den.aspects.foo.provides.impl-a
          den.aspects.foo.provides.impl-b
        ];
        den.aspects.bundle.meta.adapter = den.lib.aspects.adapters.oneOfAspects [
          den.aspects.foo.provides.impl-a
          den.aspects.foo.provides.impl-b
        ];
        den.aspects.foo.provides.impl-a.nixos = { };
        den.aspects.foo.provides.impl-b.nixos = { };

        expr = trace "nixos" den.aspects.bundle;
        expected.trace = [
          "bundle"
          [ "impl-a" ]
          [ "~impl-b" ]
        ];
      }
    );

    test-preserves-non-candidate-includes = denTest (
      { den, trace, ... }:
      {
  den.fxPipeline = false;
        den.aspects.bundle.includes = [
          den.aspects.pref-a
          den.aspects.pref-b
          den.aspects.unrelated
        ];
        den.aspects.bundle.meta.adapter = den.lib.aspects.adapters.oneOfAspects [
          den.aspects.pref-a
          den.aspects.pref-b
        ];
        den.aspects.pref-a.nixos = { };
        den.aspects.pref-b.nixos = { };
        den.aspects.unrelated.nixos = { };

        # unrelated is not a candidate and should be untouched.
        expr = trace "nixos" den.aspects.bundle;
        expected.trace = [
          "bundle"
          [ "pref-a" ]
          [ "~pref-b" ]
          [ "unrelated" ]
        ];
      }
    );

  };
}
