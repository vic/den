{ denTest, lib, ... }:
{
  flake.tests.identity-preservation =
    let
      getName =
        { aspect, recurse, ... }:
        {
          name = aspect.name;
          adapter = aspect.meta.adapter or null;
          children = map (i: (recurse i)) (aspect.includes or [ ]);
        };
    in
    {

      test-parametric-aspect-preserves-name = denTest (
        { den, ... }:
        {
          den.aspects.igloo.includes = [ den.aspects.foo ];

          den.aspects.foo =
            { host }:
            {
              nixos.environment.sessionVariables.WHO = "foo";
            };

          expr = (den.lib.aspects.resolve.withAdapter getName "nixos" den.aspects.igloo).name;
          expected = "igloo";
        }
      );

      test-parametric-child-preserves-name = denTest (
        { den, ... }:
        {
          den.aspects.foo.includes = [ den.aspects.bar ];
          den.aspects.bar =
            { host }:
            {
              nixos = { };
            };

          expr =
            let
              result = den.lib.aspects.resolve.withAdapter getName "nixos" den.aspects.foo;
            in
            (lib.head result.children).name;
          expected = "bar";
        }
      );

      test-meta-preserved-through-functor = denTest (
        { den, ... }:
        {
          den.aspects.foo.nixos = { };

          expr = (den.lib.aspects.resolve.withAdapter getName "nixos" den.aspects.foo).adapter;
          expected = null;
        }
      );

      # meta.loc, meta.name, meta.file are set by aspectMeta at merge
      # time and aren't available during functor evaluation. They don't
      # need explicit preservation — aspectType.merge provides defaults
      # for curried results, and non-curried results pass through as-is.
      test-den-meta-not-available-at-functor-eval = denTest (
        { den, ... }:
        let
          getMeta =
            { aspect, recurse, ... }:
            {
              metaName = aspect.meta.name or null;
              children = map (i: recurse i) (aspect.includes or [ ]);
            };
        in
        {
          den.aspects.foo.includes = [ den.aspects.bar ];
          den.aspects.bar =
            { host }:
            {
              nixos = { };
            };

          expr =
            let
              result = den.lib.aspects.resolve.withAdapter getMeta "nixos" den.aspects.foo;
              child = lib.head result.children;
            in
            {
              # Both get "" because aspectMeta's mkForce hasn't
              # resolved when the functor/merge runs.
              parentMetaName = result.metaName;
              childMetaName = child.metaName;
            };
          expected = {
            parentMetaName = "";
            childMetaName = "";
          };
        }
      );

    };
}
