# Tests for den.lib.aspects.adapters.collectPaths — the path-collecting
# terminal adapter used by hasAspect and other structural-query tooling.
{ denTest, lib, ... }:
{
  flake.tests.collect-paths = {

    test-basic-static-tree = denTest (
      { den, ... }:
      let
        inherit (den.lib.aspects) resolve adapters;
        paths = (resolve.withAdapter adapters.collectPaths "nixos" den.aspects.foo).paths or [ ];
        toKey = p: lib.concatStringsSep "/" p;
        keys = map toKey paths;
      in
      {
        den.fxPipeline = false;
        den.aspects.foo.includes = [
          den.aspects.bar
          den.aspects.baz
        ];
        den.aspects.bar.nixos = { };
        den.aspects.baz.nixos = { };

        expr = {
          hasFoo = lib.elem "foo" keys;
          hasBar = lib.elem "bar" keys;
          hasBaz = lib.elem "baz" keys;
          # Depth-first: foo visited first (it's the root of the walk).
          firstIsFoo = builtins.head keys == "foo";
        };
        expected = {
          hasFoo = true;
          hasBar = true;
          hasBaz = true;
          firstIsFoo = true;
        };
      }
    );

    test-empty-tree = denTest (
      { den, ... }:
      let
        inherit (den.lib.aspects) resolve adapters;
        result = resolve.withAdapter adapters.collectPaths "nixos" den.aspects.alone;
      in
      {
        den.fxPipeline = false;
        den.aspects.alone = { };

        expr = {
          pathCount = builtins.length (result.paths or [ ]);
          hasSelf = builtins.elem [ "alone" ] (result.paths or [ ]);
        };
        expected = {
          pathCount = 1;
          hasSelf = true;
        };
      }
    );

    test-forces-parametric-functors = denTest (
      { den, ... }:
      let
        inherit (den.lib.aspects) resolve adapters;
        paths = (resolve.withAdapter adapters.collectPaths "nixos" den.aspects.role).paths or [ ];
        keys = map (lib.concatStringsSep "/") paths;
      in
      {
        den.fxPipeline = false;
        # role (static) includes a perHost parametric aspect; collectPaths
        # should force the functor and include its entry in the path list.
        den.aspects.role.includes = [
          den.aspects.leaf
          den.aspects.param
        ];
        den.aspects.leaf.nixos = { };
        den.aspects.param = den.lib.perHost (
          { host }:
          {
            nixos = { };
          }
        );

        expr = {
          hasRole = lib.elem "role" keys;
          hasLeaf = lib.elem "leaf" keys;
          hasParam = lib.elem "param" keys;
        };
        expected = {
          hasRole = true;
          hasLeaf = true;
          hasParam = true;
        };
      }
    );

    test-skips-tombstones = denTest (
      { den, ... }:
      let
        inherit (den.lib.aspects) resolve adapters;
        paths = (resolve.withAdapter adapters.collectPaths "nixos" den.aspects.root).paths or [ ];
        keys = map (lib.concatStringsSep "/") paths;
      in
      {
        den.fxPipeline = false;
        den.aspects.root.includes = [
          den.aspects.keep
          den.aspects.dropme
        ];
        den.aspects.root.meta.adapter = inherited: adapters.excludeAspect den.aspects.dropme inherited;
        den.aspects.keep.nixos = { };
        den.aspects.dropme.nixos = { };

        expr = {
          hasKeep = lib.elem "keep" keys;
          hasDropme = lib.elem "dropme" keys;
        };
        expected = {
          hasKeep = true;
          hasDropme = false;
        };
      }
    );

    test-shared-subtree-not-deduped = denTest (
      { den, ... }:
      let
        inherit (den.lib.aspects) resolve adapters;
        paths = (resolve.withAdapter adapters.collectPaths "nixos" den.aspects.root).paths or [ ];
        keys = map (lib.concatStringsSep "/") paths;
        sharedCount = builtins.length (builtins.filter (k: k == "shared") keys);
      in
      {
        den.fxPipeline = false;
        # `shared` reached via both `a` and `b`.
        den.aspects.root.includes = [
          den.aspects.a
          den.aspects.b
        ];
        den.aspects.a.includes = [ den.aspects.shared ];
        den.aspects.b.includes = [ den.aspects.shared ];
        den.aspects.shared.nixos = { };

        # collectPaths does NOT dedupe — each visit produces a path.
        expr = sharedCount;
        expected = 2;
      }
    );

    test-provider-path-included = denTest (
      { den, ... }:
      let
        inherit (den.lib.aspects) resolve adapters;
        paths = (resolve.withAdapter adapters.collectPaths "nixos" den.aspects.root).paths or [ ];
      in
      {
        den.fxPipeline = false;
        den.aspects.root.includes = [ den.aspects.foo.provides.sub ];
        den.aspects.foo.provides.sub.nixos = { };

        expr = lib.elem [ "foo" "sub" ] paths;
        expected = true;
      }
    );

  };
}
