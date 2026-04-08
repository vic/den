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
        expected.trace = [
          "foo"
          [ "bar" ]
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
            outerAdapter = adapters.filter (a: a.name != "baz") adapters.traceName;
          in
          resolve.withAdapter (adapters.filterIncludes outerAdapter) "nixos" den.aspects.foo;
        expected.trace = [
          "foo"
        ];
      }
    );

  };
}
