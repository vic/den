{ denTest, lib, ... }:
{
  flake.tests.ctx-nested = {

    test-two-level-nesting = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.ns.inner._.inner =
          { z }:
          {
            funny.names = [ "inner-${z}" ];
          };

        den.ctx.root._.root =
          { v }:
          {
            funny.names = [ v ];
          };
        den.ctx.root.into =
          { v }:
          {
            ns.inner = [ { z = v; } ];
          };

        expr = funnyNames (den.ctx.root { v = "hello"; });
        expected = [
          "hello"
          "inner-hello"
        ];
      }
    );

    test-three-level-nesting = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.a.b.c._.c =
          { z }:
          {
            funny.names = [ "abc-${z}" ];
          };

        den.ctx.start.into =
          { z }:
          {
            a.b.c = [ { z = z; } ];
          };

        expr = funnyNames (den.ctx.start { z = "deep"; });
        expected = [ "abc-deep" ];
      }
    );

    test-dedup-by-full-path = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.a.leaf._.leaf =
          { v }:
          {
            funny.names = [ "a-${v}" ];
          };
        den.ctx.b.leaf._.leaf =
          { v }:
          {
            funny.names = [ "b-${v}" ];
          };

        den.ctx.root.into = _: {
          a.leaf = [ { v = "x"; } ];
          b.leaf = [ { v = "y"; } ];
        };

        expr = funnyNames (den.ctx.root { });
        expected = [
          "a-x"
          "b-y"
        ];
      }
    );

    test-flat-still-works = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.flat._.flat =
          { x }:
          {
            funny.names = [ x ];
          };

        den.ctx.root.into.flat = lib.singleton;

        expr = funnyNames (den.ctx.root { x = "hi"; });
        expected = [ "hi" ];
      }
    );

    test-into-mixed-flat-and-nested = denTest (
      { den, funnyNames, ... }:
      {
        den.ctx.ns.deep._.deep =
          { k }:
          {
            funny.names = [ "deep-${k}" ];
          };
        den.ctx.flat._.flat =
          { k }:
          {
            funny.names = [ "flat-${k}" ];
          };

        den.ctx.root.into =
          { k }:
          {
            flat = [ { inherit k; } ];
            ns.deep = [ { inherit k; } ];
          };

        expr = funnyNames (den.ctx.root { k = "v"; });
        expected = [
          "deep-v"
          "flat-v"
        ];
      }
    );
  };
}
