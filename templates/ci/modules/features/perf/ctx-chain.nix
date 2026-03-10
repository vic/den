{ denTest, lib, ... }:
let
  mkCtxModules =
    n:
    lib.genList (
      i:
      let
        name = "ctx-${toString i}";
        next = "ctx-${toString (i + 1)}";
        base = {
          description = name;
          _.${name} =
            { x }:
            {
              funny.names = [ "${name}-${x}" ];
            };
        };
        withInto =
          if i + 1 < n then
            {
              into.${next} = { x }: [ { x = "${x}+${toString i}"; } ];
            }
          else
            { };
      in
      { den, ... }:
      {
        den.ctx.${name} = base // withInto;
      }
    ) n;
in
{
  flake.tests.perf-ctx = {

    test-ctx-chain-5 = denTest (
      { den, funnyNames, ... }:
      {
        imports = mkCtxModules 5;
        expr = builtins.length (funnyNames (den.ctx.ctx-0 { x = "v"; }));
        expected = 5;
      }
    );

    test-ctx-chain-10 = denTest (
      { den, funnyNames, ... }:
      {
        imports = mkCtxModules 10;
        expr = builtins.length (funnyNames (den.ctx.ctx-0 { x = "v"; }));
        expected = 10;
      }
    );

    test-ctx-chain-20 = denTest (
      { den, funnyNames, ... }:
      {
        imports = mkCtxModules 20;
        expr = builtins.length (funnyNames (den.ctx.ctx-0 { x = "v"; }));
        expected = 20;
      }
    );

    test-ctx-fan-out-20 = denTest (
      { den, funnyNames, ... }:
      {
        imports = [
          (
            { den, ... }:
            {
              den.ctx.root = {
                description = "root";
                _.root =
                  { x }:
                  {
                    funny.names = [ "root-${x}" ];
                  };
                into.leaf = { x }: lib.genList (i: { x = "${x}-${toString i}"; }) 20;
              };
              den.ctx.leaf._.leaf =
                { x }:
                {
                  funny.names = [ "leaf-${x}" ];
                };
            }
          )
        ];
        expr = builtins.length (funnyNames (den.ctx.root { x = "v"; }));
        expected = 21;
      }
    );

  };
}
