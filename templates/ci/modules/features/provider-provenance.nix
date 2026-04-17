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
          den.fxPipeline = false;
          den.aspects.foo.nixos = { };

          expr = (den.lib.aspects.resolve.withAdapter getProvenance "nixos" den.aspects.foo).provider;
          expected = [ ];
        }
      );

      test-provided-aspect-has-provider-path = denTest (
        { den, ... }:
        {
          den.fxPipeline = false;
          den.aspects.foo.includes = [ den.aspects.foo.provides.bar ];
          den.aspects.foo.provides.bar.nixos = { };

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
          den.fxPipeline = false;
          den.aspects.foo.provides.bar.includes = [ den.aspects.foo.provides.bar.provides.baz ];
          den.aspects.foo.provides.bar.provides.baz.nixos = { };
          den.aspects.foo.includes = [ den.aspects.foo.provides.bar ];

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
          den.fxPipeline = false;
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
