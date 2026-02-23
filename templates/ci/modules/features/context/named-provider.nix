{ denTest, ... }:
{
  flake.tests.ctx-named-provider = {

    test-self-named-provider = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.greet.description = "{who} context";
        den.ctx.greet._.greet =
          { who }:
          {
            funny.names = [ "hello-${who}" ];
          };

        expr = funnyNames (den.ctx.greet { who = "nix"; });
        expected = [ "hello-nix" ];
      }
    );

    test-self-named-plus-owned = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.greet.description = "{who} context";
        den.ctx.greet._.greet =
          { who }:
          {
            funny.names = [ "hello-${who}" ];
          };
        den.ctx.greet.funny.names = [ "owned" ];

        expr = funnyNames (den.ctx.greet { who = "nix"; });
        expected = [
          "hello-nix"
          "owned"
        ];
      }
    );

    test-named-provider-with-into = denTest (
      {
        den,
        lib,
        funnyNames,
        ...
      }:
      {
        den.ctx.greet.description = "{who} context";
        den.ctx.greet._.greet =
          { who }:
          {
            funny.names = [ who ];
          };
        den.ctx.greet.into.yell = { who }: [ { shout = lib.toUpper who; } ];

        den.ctx.yell._.yell =
          { shout }:
          {
            funny.names = [ shout ];
          };

        expr = funnyNames (den.ctx.greet { who = "world"; });
        expected = [
          "WORLD"
          "world"
        ];
      }
    );

  };
}
