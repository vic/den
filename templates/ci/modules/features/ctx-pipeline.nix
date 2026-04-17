{ denTest, lib, ... }:
let
  mkCtxChain =
    n:
    lib.genList (
      i:
      let
        name = "c${toString i}";
        next = "c${toString (i + 1)}";
        base = {
          _.${name} =
            { x }:
            {
              funny.names = [ "${name}-${x}" ];
            };
        };
        withInto = if i + 1 < n then { into.${next} = { x }: [ { x = "${x}+${toString i}"; } ]; } else { };
      in
      { den, ... }:
      {
        den.ctx.${name} = base // withInto;
      }
    ) n;

  mkFanOut =
    n:
    { den, ... }:
    {
      den.ctx.root = {
        _.root =
          { x }:
          {
            funny.names = [ "root-${x}" ];
          };
        into.leaf = { x }: lib.genList (i: { x = "${x}-${toString i}"; }) n;
      };
      den.ctx.leaf.provides.leaf =
        { x }:
        {
          funny.names = [ "leaf-${x}" ];
        };
    };

  mkCrossProviders =
    n:
    let
      srcMod =
        { den, ... }:
        {
          den.ctx.src = {
            _.src =
              { v }:
              {
                funny.names = [ "src-${v}" ];
              };
            into = lib.genAttrs (lib.genList (i: "t${toString i}") n) (_: { v }: [ { v = "${v}!"; } ]);
            provides = lib.genAttrs (lib.genList (i: "t${toString i}") n) (
              name: _:
              { v }:
              {
                funny.names = [ "cross-${name}-${v}" ];
              }
            );
          };
        };
      targetMods = lib.genList (
        i:
        let
          name = "t${toString i}";
        in
        { den, ... }:
        {
          den.ctx.${name}.provides.${name} =
            { v }:
            {
              funny.names = [ "${name}-${v}" ];
            };
        }
      ) n;
    in
    [ srcMod ] ++ targetMods;

in
{
  flake.tests.performance.ctx = {

    test-chain-30 = denTest (
      { den, funnyNames, ... }:
      {
        imports = mkCtxChain 30;
        expr = builtins.length (funnyNames (den.ctx.c0 { x = "v"; }));
        expected = 30;
      }
    );

    test-fan-out-50 = denTest (
      { den, funnyNames, ... }:
      {
        imports = [ (mkFanOut 50) ];
        expr = builtins.length (funnyNames (den.ctx.root { x = "v"; }));
        expected = 51;
      }
    );

    test-cross-providers-20 = denTest (
      { den, funnyNames, ... }:
      {
        imports = mkCrossProviders 20;
        expr = builtins.length (funnyNames (den.ctx.src { v = "z"; }));
        expected = 41;
      }
    );

  };
}
