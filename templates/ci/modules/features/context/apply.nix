{ denTest, ... }:
{
  flake.tests.ctx.test-apply = denTest (
    { den, funnyNames, ... }:
    {
      den.ctx.foobar.description = "{foo,bar} context";
      den.ctx.foobar._.foobar =
        { foo, bar }:
        {
          funny.names = [
            foo
            bar
          ];
        };

      den.ctx.foobar.funny.names = [ "owned" ];

      expr = funnyNames (
        den.ctx.foobar {
          foo = "moo";
          bar = "baa";
        }
      );

      expected = [
        "baa"
        "moo"
        "owned"
      ];
    }
  );
}
