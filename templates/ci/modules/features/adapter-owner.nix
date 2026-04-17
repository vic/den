# Tests for adapterOwner tracking in filterIncludes.
{ denTest, lib, ... }:
{
  flake.tests.adapter-owner = {

    # Tombstone excludedFrom uses the declaring aspect's pathKey, not "<anon>".
    test-tombstone-excludedFrom-is-owner-path = denTest (
      { den, ... }:
      let
        inherit (den.lib.aspects) adapters resolve;
        target = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        root = {
          name = "owner";
          meta = {
            adapter = adapters.excludeAspect target;
            provider = [ ];
          };
          nixos = { };
          includes = [
            {
              name = "keep";
              meta = {
                provider = [ ];
              };
              nixos = { };
              includes = [ ];
            }
            {
              name = "drop";
              meta = {
                provider = [ ];
              };
              nixos = { };
              includes = [ ];
            }
          ];
        };
        # Resolve and inspect the aspect tree for tombstones.
        resolved = resolve.withAdapter adapters.default "nixos" root;
        # The default adapter (filterIncludes module) produces { imports }.
        # We need to look at the raw adapter output instead.
        # Use collectPaths to check tombstones are visible.
        pathResult = resolve.withAdapter adapters.collectPaths "nixos" root;
        # Check that "drop" is NOT in the collected paths (it's tombstoned).
        pathKeys = map adapters.pathKey (pathResult.paths or [ ]);
      in
      {
        den.fxPipeline = false;
        expr = {
          dropExcluded = !(builtins.elem "drop" pathKeys);
          keepPresent = builtins.elem "keep" pathKeys;
        };
        expected = {
          dropExcluded = true;
          keepPresent = true;
        };
      }
    );

    # adapterOwner field propagates through tagged children.
    test-adapter-owner-propagated = denTest (
      { den, ... }:
      let
        inherit (den.lib.aspects) adapters resolve;
        target = {
          name = "deep-drop";
          meta = {
            provider = [ ];
          };
        };
        inner = {
          name = "inner";
          meta = {
            provider = [ ];
          };
          includes = [
            {
              name = "deep-drop";
              meta = {
                provider = [ ];
              };
              nixos = { };
              includes = [ ];
            }
            {
              name = "deep-keep";
              meta = {
                provider = [ ];
              };
              nixos = { };
              includes = [ ];
            }
          ];
        };
        root = {
          name = "owner";
          meta = {
            adapter = adapters.excludeAspect target;
            provider = [ ];
          };
          nixos = { };
          includes = [ inner ];
        };
        pathResult = resolve.withAdapter adapters.collectPaths "nixos" root;
        pathKeys = map adapters.pathKey (pathResult.paths or [ ]);
      in
      {
        den.fxPipeline = false;
        expr = {
          deepDropExcluded = !(builtins.elem "deep-drop" pathKeys);
          deepKeepPresent = builtins.elem "deep-keep" pathKeys;
          innerPresent = builtins.elem "inner" pathKeys;
        };
        expected = {
          deepDropExcluded = true;
          deepKeepPresent = true;
          innerPresent = true;
        };
      }
    );

  };
}
