{ denTest, ... }:
{
  flake.tests.with-sub-aspects = {
    test-is-in-lib = denTest (
      { den, lib, ... }:
      {
        expr = lib.isFunction den.lib.withSubAspectsOf;
        expected = true;
      }
    );

    test-works-with-empty-values = denTest (
      { den, ... }:
      {
        expr = den.lib.withSubAspectsOf [ ] [ ];
        expected = [ ];
      }
    );

    test-works-with-direct-includes = denTest (
      { den, ... }:
      {
        den.aspects.foo = _: { };

        expr = den.lib.withSubAspectsOf [ ] [ den.aspects.foo ];
        expected = [ den.aspects.foo ];
      }
    );

    test-works-with-sub-aspects = denTest (
      { den, ... }:
      {
        den.aspects.foo = { };
        den.aspects.foo._.bar = { };

        expr = den.lib.withSubAspectsOf [ "foo" ] [ ];
        expected = [ den.aspects.foo._.bar ];
      }
    );

    test-works-with-both-sub-aspects-and-direct-includes = denTest (
      { den, ... }:
      {
        den.aspects.foo = { };
        den.aspects.foo._.bar = { };
        den.aspects.baz = { };

        expr = den.lib.withSubAspectsOf [ "foo" ] [ den.aspects.baz ];
        expected = [
          den.aspects.foo._.bar
          den.aspects.baz
        ];
      }
    );
  };
}
