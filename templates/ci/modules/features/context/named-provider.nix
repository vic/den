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

    test-self-provides-other = denTest (
      {
        den,
        lib,
        funnyNames,
        ...
      }:
      {
        den.ctx.greet._.greet =
          { who }:
          {
            funny.names = [ "hello-${who}" ];
          };

        den.ctx.greet.into.other = lib.singleton;
        den.ctx.greet.provides.other =
          { who }:
          {
            funny.names = [ "other-${who}" ];
          };

        expr = funnyNames (den.ctx.greet { who = "nix"; });
        expected = [
          "hello-nix"
          "other-nix"
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

    test-named-provider-with-into-fn = denTest (
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
        den.ctx.greet.into =
          { who }:
          {
            yell = [ { shout = lib.toUpper who; } ];
            size = [ { length = lib.stringLength who; } ];
            num = [ { number = lib.stringLength who; } ];
          };

        den.ctx.yell._.yell =
          { shout }:
          {
            funny.names = [ shout ];
          };

        den.ctx.size.provides.size =
          { length }:
          {
            funny.names = [ (lib.toString length) ];
          };

        den.ctx.greet.provides.num =
          { number }:
          {
            funny.names = [ ("num:" + lib.toString number) ];
          };

        expr = funnyNames (den.ctx.greet { who = "world"; });
        expected = [
          "5"
          "WORLD"
          "num:5"
          "world"
        ];
      }
    );

  };
}
