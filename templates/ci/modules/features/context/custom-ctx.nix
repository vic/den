{ denTest, ... }:
{
  flake.tests.ctx-custom = {

    test-ctx-into = denTest (
      {
        den,
        lib,
        funnyNames,
        ...
      }:
      {
        den.ctx.greeting.description = "{hello} context";
        den.ctx.greeting._.greeting =
          { hello }:
          {
            funny.names = [ hello ];
          };
        den.ctx.greeting.into.shout = { hello }: [ { shout = lib.toUpper hello; } ];

        den.ctx.shout._.shout =
          { shout }:
          {
            funny.names = [ shout ];
          };

        expr = funnyNames (den.ctx.greeting { hello = "world"; });
        expected = [
          "WORLD"
          "world"
        ];
      }
    );

    test-ctx-includes-static-and-parametric = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.foo.description = "{foo} context";
        den.ctx.foo._.foo =
          { foo }:
          {
            funny.names = [ foo ];
          };
        den.ctx.foo.includes = [
          { funny.names = [ "static-include" ]; }
          (
            { foo, ... }:
            {
              funny.names = [ "param-${foo}" ];
            }
          )
        ];

        expr = funnyNames (den.ctx.foo { foo = "hello"; });
        expected = [
          "hello"
          "param-hello"
          "static-include"
        ];
      }
    );

    test-ctx-owned = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.bar.description = "{x} context";
        den.ctx.bar._.bar =
          { x }:
          {
            funny.names = [ x ];
          };
        den.ctx.bar.funny.names = [ "owned" ];

        expr = funnyNames (den.ctx.bar { x = "val"; });
        expected = [
          "owned"
          "val"
        ];
      }
    );

  };
}
