{ denTest, ... }:
{
  flake.tests.ctx-non-exact.test-apply-non-exact-less = denTest (
    { den, funnyNames, ... }:
    {
      den.ctx.foobar.description = "{foo,bar} context";
      den.ctx.foobar._.foobar =
        # use atLeast if you get error: function called with unexpected argument
        den.lib.take.atLeast (
          { foo, bar }:
          {
            funny.names = [
              foo
              bar
            ];
          }
        );

      expr = funnyNames (
        den.ctx.foobar {
          foo = "moo";
          # missing bar
        }
      );

      expected = [ ];
    }
  );

  flake.tests.ctx-non-exact.test-apply-non-exact-more = denTest (
    { den, funnyNames, ... }:
    {
      den.ctx.foobar.description = "{foo,bar} context";
      den.ctx.foobar._.foobar =
        # use exactly if you want to restrict to not having more args
        den.lib.take.exactly (
          { foo, bar }:
          {
            funny.names = [
              foo
              bar
            ];
          }
        );

      expr = funnyNames (
        den.ctx.foobar {
          foo = "moo";
          bar = "bar";
          baz = "man";
        }
      );

      expected = [ ];
    }
  );
}
