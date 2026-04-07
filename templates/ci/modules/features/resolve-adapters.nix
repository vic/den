{ denTest, lib, ... }:
{
  flake.tests.resolve-adapters =
    let
      traceName =
        { aspect, recurse, ... }:
        {
          trace = [ aspect.name ] ++ map (i: (recurse i).trace or [ ]) (aspect.includes or [ ]);
        };
    in
    {

      test-basic-trace-includes = denTest (
        { den, lib, ... }:
        {

          den.aspects.foo.includes = [ den.aspects.bar ];
          den.aspects.bar.includes = [ den.aspects.baz ];
          den.aspects.baz.nixos = { };

          expr = den.lib.aspects.resolve.withAdapter traceName "nixos" den.aspects.foo;
          expected.trace = [
            "foo"
            [
              "bar"
              [ "baz" ]
            ]
          ];
        }
      );

      test-filter-compose-with-trace-includes = denTest (
        { den, lib, ... }:
        {

          den.aspects.foo.includes = [ den.aspects.bar ];
          den.aspects.bar.includes = [ den.aspects.baz ];
          den.aspects.baz.nixos = { };

          expr =
            let
              inherit (den.lib.aspects) resolve adapters;
              notBar = adapters.filter (aspect: aspect.name != "bar");
              composed = notBar traceName;
            in
            resolve.withAdapter composed "nixos" den.aspects.foo;
          expected.trace = [
            "foo"
            [ ]
          ];
        }
      );

    };
}
