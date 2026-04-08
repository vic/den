{ denTest, lib, ... }:
{
  flake.tests.aspect-adapter =
    let
      traceName =
        { aspect, recurse, ... }:
        {
          trace = [ aspect.name ] ++ map (i: (recurse i).trace or [ ]) (aspect.includes or [ ]);
        };
    in
    {

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

          expr =
            den.lib.aspects.resolve.withAdapter (den.lib.aspects.adapters.filterIncludes traceName) "nixos"
              den.aspects.foo;
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

          expr =
            den.lib.aspects.resolve.withAdapter (den.lib.aspects.adapters.filterIncludes traceName) "nixos"
              den.aspects.root;
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
              outerAdapter = den.lib.aspects.adapters.filter (a: a.name != "baz") traceName;
            in
            den.lib.aspects.resolve.withAdapter (den.lib.aspects.adapters.filterIncludes outerAdapter) "nixos"
              den.aspects.foo;
          expected.trace = [
            "foo"
          ];
        }
      );

    };
}
