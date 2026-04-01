{ denTest, lib, ... }:
{
  flake.tests.performance.parametric = {

    test-fixedTo-deep-chain = denTest (
      { den, funnyNames, ... }:
      let
        leaf = den.lib.parametric {
          funny.names = [ "leaf" ];
        };
        mid = den.lib.parametric {
          funny.names = [ "mid" ];
          includes = [ leaf ];
        };
        top = den.lib.parametric.fixedTo { level = "deep"; } {
          funny.names = [ "top" ];
          includes = lib.genList (_: mid) 20;
        };
      in
      {
        den.ctx.start = {
          _.start =
            { level }:
            {
              funny.names = [ level ];
            };
          includes = [ top ];
        };

        expr = builtins.length (funnyNames (den.ctx.start { level = "deep"; }));
        expected = 42;
      }
    );

    test-atLeast-wide = denTest (
      { den, funnyNames, ... }:
      let
        mkParam =
          i:
          den.lib.parametric {
            funny.names = [ "p${toString i}" ];
            includes = [
              (
                { host, ... }:
                {
                  funny.names = [ "i${toString i}-${host}" ];
                }
              )
            ];
          };
        aspects = lib.genList mkParam 30;
      in
      {
        den.ctx.start = {
          _.start =
            { host }:
            {
              funny.names = [ host ];
            };
          includes = aspects;
        };

        expr = builtins.length (funnyNames (den.ctx.start { host = "h"; }));
        expected = 61;
      }
    );

    test-expands-propagation = denTest (
      { den, funnyNames, ... }:
      let
        inner =
          { host, planet, ... }:
          {
            funny.names = [ "${host}-${planet}" ];
          };
        expanded = den.lib.parametric.expands { planet = "mars"; } {
          funny.names = [ "exp" ];
          includes = lib.genList (_: inner) 15;
        };
      in
      {
        den.ctx.start = {
          _.start =
            { host }:
            {
              funny.names = [ host ];
            };
          includes = [ expanded ];
        };

        expr = builtins.length (funnyNames (den.ctx.start { host = "h"; }));
        expected = 17;
      }
    );

    test-dedup-parametric = denTest (
      { den, funnyNames, ... }:
      let
        shared = den.lib.parametric {
          funny.names = [ "shared" ];
          includes = [
            (
              { host, ... }:
              {
                funny.names = [ "inner-${host}" ];
              }
            )
          ];
        };
      in
      {
        den.ctx.a = {
          _.a =
            { host }:
            {
              funny.names = [ "a-${host}" ];
            };
          into.b = { host }: [ { host = "${host}!"; } ];
          includes = [ shared ];
        };
        den.ctx.b = {
          _.b =
            { host }:
            {
              funny.names = [ "b-${host}" ];
            };
          includes = [ shared ];
        };

        expr = builtins.length (funnyNames (den.ctx.a { host = "v"; }));
        expected = 6;
      }
    );

  };
}
