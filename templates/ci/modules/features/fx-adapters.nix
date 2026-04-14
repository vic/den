{
  denTest,
  inputs,
  lib,
  ...
}:
let
  fx = inputs.nix-effects.lib;
in
{
  flake.tests.fx-adapters = {

    test-exclude-declaration = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        decl = fxLib.adapters.excludeAspect ref;
      in
      {
        expr = {
          type = decl.type;
          identity = decl.identity;
        };
        expected = {
          type = "exclude";
          identity = "drop";
        };
      }
    );

    test-substitute-declaration = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "old";
          meta = {
            provider = [ ];
          };
        };
        replacement = {
          name = "new";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        decl = fxLib.adapters.substituteAspect ref replacement;
      in
      {
        expr = {
          type = decl.type;
          identity = decl.identity;
          replacementName = decl.replacement.name;
        };
        expected = {
          type = "substitute";
          identity = "old";
          replacementName = "new";
        };
      }
    );

    test-exclude-via-registry = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        decl = fxLib.adapters.excludeAspect ref;
        # Register then check-exclusion
        comp = fx.bind (fx.send "register-adapter" (decl // { owner = "test"; })) (
          _: fx.send "check-exclusion" "drop"
        );
        result = fx.handle {
          handlers = fxLib.handlers.adapterRegistryHandler;
          state = {
            adapterRegistry = { };
          };
        } comp;
      in
      {
        expr = result.value.action;
        expected = "exclude";
      }
    );

    test-check-exclusion-default-keep = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        comp = fx.send "check-exclusion" "unknown";
        result = fx.handle {
          handlers = fxLib.handlers.adapterRegistryHandler;
          state = {
            adapterRegistry = { };
          };
        } comp;
      in
      {
        expr = result.value.action;
        expected = "keep";
      }
    );

    test-substitute-via-registry = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "old";
          meta = {
            provider = [ ];
          };
        };
        replacement = {
          name = "new";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        decl = fxLib.adapters.substituteAspect ref replacement;
        comp = fx.bind (fx.send "register-adapter" (decl // { owner = "test"; })) (
          _: fx.send "check-exclusion" "old"
        );
        result = fx.handle {
          handlers = fxLib.handlers.adapterRegistryHandler;
          state = {
            adapterRegistry = { };
          };
        } comp;
      in
      {
        expr = {
          action = result.value.action;
          replacementName = result.value.replacement.name;
        };
        expected = {
          action = "substitute";
          replacementName = "new";
        };
      }
    );

    test-provideClassHandler-collects-imports = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        parent = {
          name = "root";
          meta = { };
          includes = [
            {
              name = "a";
              meta = { };
              nixos = {
                enable = true;
              };
              includes = [ ];
            }
            {
              name = "b";
              meta = { };
              includes = [ ];
            }
          ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers = {
            "resolve-include" =
              { param, state }:
              {
                resume = param;
                inherit state;
              };
            "resolve-complete" =
              { param, state }:
              {
                resume = param;
                inherit state;
              };
            "check-exclusion" =
              { param, state }:
              {
                resume = {
                  action = "keep";
                };
                inherit state;
              };
          }
          // fxLib.handlers.provideClassHandler;
          state = {
            imports = [ ];
          };
        } comp;
      in
      {
        expr = builtins.length result.state.imports;
        expected = 1;
      }
    );

    test-collectPaths-excludes-tombstones = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        target = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        parent = {
          name = "root";
          meta = {
            adapter = fxLib.adapters.excludeAspect target;
          };
          includes = [
            {
              name = "keep";
              meta = {
                provider = [ ];
              };
              includes = [ ];
            }
            {
              name = "drop";
              meta = {
                provider = [ ];
              };
              includes = [ ];
            }
          ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers = {
            "resolve-include" =
              { param, state }:
              {
                resume = param;
                inherit state;
              };
          }
          // fxLib.handlers.adapterRegistryHandler
          // fxLib.adapters.collectPathsHandler;
          state = {
            paths = [ ];
            adapterRegistry = { };
          };
        } comp;
      in
      {
        expr = builtins.length result.state.paths;
        expected = 1;
      }
    );

    test-provideClassHandler-skips-tombstones = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        target = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        parent = {
          name = "root";
          meta = {
            adapter = fxLib.adapters.excludeAspect target;
          };
          includes = [
            {
              name = "keep";
              meta = {
                provider = [ ];
              };
              nixos = {
                a = 1;
              };
              includes = [ ];
            }
            {
              name = "drop";
              meta = {
                provider = [ ];
              };
              nixos = {
                b = 2;
              };
              includes = [ ];
            }
          ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers = {
            "resolve-include" =
              { param, state }:
              {
                resume = param;
                inherit state;
              };
            "resolve-complete" =
              { param, state }:
              {
                resume = param;
                inherit state;
              };
          }
          // fxLib.handlers.adapterRegistryHandler
          // fxLib.handlers.provideClassHandler;
          state = {
            imports = [ ];
            adapterRegistry = { };
          };
        } comp;
      in
      {
        expr = builtins.length result.state.imports;
        expected = 1;
      }
    );

  };
}
