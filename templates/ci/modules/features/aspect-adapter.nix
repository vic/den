{ denTest, lib, ... }:
{
  flake.tests.aspect-adapter = {

    test-meta-adapter-filters-subtree = denTest (
      { den, ... }:
      {
        den.aspects.foo.includes = [
          den.aspects.bar
          den.aspects.baz
        ];
        den.aspects.foo.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: a.name != "baz") inherited;
        den.aspects.bar.nixos = { };
        den.aspects.baz.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.foo;
        # baz tombstone visible in trace
        expected.trace = [
          "foo"
          [ "bar" ]
          [ "~baz" ]
        ];
      }
    );

    test-meta-adapter-only-affects-subtree = denTest (
      { den, ... }:
      {
        den.aspects.root.includes = [
          den.aspects.foo
          den.aspects.baz
        ];
        den.aspects.foo.includes = [ den.aspects.bar ];
        den.aspects.foo.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: a.name != "baz") inherited;
        den.aspects.bar.nixos = { };
        den.aspects.baz.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.root;
        # foo's adapter only affects its subtree; root's baz is unaffected
        expected.trace = [
          "root"
          [
            "foo"
            [ "bar" ]
          ]
          [ "baz" ]
        ];
      }
    );

    test-meta-adapter-composes-with-caller = denTest (
      { den, ... }:
      {
        den.aspects.foo.includes = [
          den.aspects.bar
          den.aspects.baz
        ];
        den.aspects.foo.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: a.name != "bar") inherited;
        den.aspects.bar.nixos = { };
        den.aspects.baz.nixos = { };

        expr =
          let
            inherit (den.lib.aspects) resolve adapters;
            outerTrace = adapters.filter (a: a.name != "baz") adapters.trace;
          in
          resolve.withAdapter outerTrace "nixos" den.aspects.foo;
        # bar tombstoned by meta.adapter, baz killed by outer filter (no tombstone
        # since the outer filter is not wrapped in filterIncludes)
        expected.trace = [
          "foo"
          [ "~bar" ]
          [ ]
        ];
      }
    );

  };
}
