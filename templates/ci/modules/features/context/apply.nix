{ denTest, ... }:
{
  flake.tests.ctx.test-apply = denTest (
    { den, funnyNames, ... }:
    {
      den.ctx.foobar.desc = "{foo,bar} context";
      den.ctx.foobar.conf =
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
