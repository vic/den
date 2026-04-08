{ denTest, lib, ... }:
{
  flake.tests.provider-provenance =
    let
      getProvenance =
        { aspect, recurse, ... }:
        {
          name = aspect.name;
          provider = aspect.meta.provider or [ ];
          children = map (i: recurse i) (aspect.includes or [ ]);
        };
    in
    {

      test-top-level-has-empty-provider = denTest (
        { den, ... }:
        {
          den.aspects.foo.nixos = { };

          expr = (den.lib.aspects.resolve.withAdapter getProvenance "nixos" den.aspects.foo).provider;
          expected = [ ];
        }
      );

      test-provided-aspect-has-provider-path = denTest (
        { den, ... }:
        {
          den.aspects.foo.includes = [ den.aspects.foo._.bar ];
          den.aspects.foo._.bar.nixos = { };

          expr =
            let
              result = den.lib.aspects.resolve.withAdapter getProvenance "nixos" den.aspects.foo;
            in
            (lib.head result.children).provider;
          expected = [ "foo" ];
        }
      );

      test-deep-provider-chain = denTest (
        { den, ... }:
        {
          den.aspects.foo._.bar.includes = [ den.aspects.foo._.bar._.baz ];
          den.aspects.foo._.bar._.baz.nixos = { };
          den.aspects.foo.includes = [ den.aspects.foo._.bar ];

          expr =
            let
              result = den.lib.aspects.resolve.withAdapter getProvenance "nixos" den.aspects.foo;
              barResult = lib.head result.children;
            in
            (lib.head barResult.children).provider;
          expected = [
            "foo"
            "bar"
          ];
        }
      );

      test-namespace-provider-root = denTest (
        { den, ... }:
        {
          den.provides.myaspect.nixos = { };

          expr = (den.lib.aspects.resolve.withAdapter getProvenance "nixos" den.provides.myaspect).provider;
          expected = [
            "den"
            "provides"
          ];
        }
      );

    };
}
