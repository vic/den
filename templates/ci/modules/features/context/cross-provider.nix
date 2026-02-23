{ denTest, ... }:
{
  flake.tests.ctx-cross-provider = {

    test-source-provides-target = denTest (
      {
        den,
        lib,
        funnyNames,
        ...
      }:
      {
        den.ctx.parent.description = "{x} context";
        den.ctx.parent._.parent =
          { x }:
          {
            funny.names = [ "parent-${x}" ];
          };
        den.ctx.parent._.child =
          { x, y }:
          {
            funny.names = [ "parent-for-child-${x}-${y}" ];
          };
        den.ctx.parent.into.child = { x }: [ { inherit x; y = "derived"; } ];

        den.ctx.child._.child =
          { x, y }:
          {
            funny.names = [ "child-${y}" ];
          };

        expr = funnyNames (den.ctx.parent { x = "hello"; });
        expected = [
          "child-derived"
          "parent-for-child-hello-derived"
          "parent-hello"
        ];
      }
    );

    test-source-provider-per-target-value = denTest (
      {
        den,
        lib,
        funnyNames,
        ...
      }:
      {
        den.ctx.src.description = "source";
        den.ctx.src._.src = { x }: { funny.names = [ x ]; };
        den.ctx.src._.dst =
          { x, i }:
          {
            funny.names = [ "src-for-${x}-${toString i}" ];
          };
        den.ctx.src.into.dst = { x }: [
          { inherit x; i = 1; }
          { inherit x; i = 2; }
        ];

        den.ctx.dst._.dst =
          { x, i }:
          {
            funny.names = [ "dst-${toString i}" ];
          };

        expr = funnyNames (den.ctx.src { x = "a"; });
        expected = [
          "a"
          "dst-1"
          "dst-2"
          "src-for-a-1"
          "src-for-a-2"
        ];
      }
    );

    test-no-cross-provider-when-absent = denTest (
      {
        den,
        lib,
        funnyNames,
        ...
      }:
      {
        den.ctx.src.description = "source without cross-provider";
        den.ctx.src._.src = { x }: { funny.names = [ x ]; };
        den.ctx.src.into.dst = { x }: [ { y = x; } ];

        den.ctx.dst._.dst = { y }: { funny.names = [ "dst-${y}" ]; };

        expr = funnyNames (den.ctx.src { x = "val"; });
        expected = [
          "dst-val"
          "val"
        ];
      }
    );

  };
}
