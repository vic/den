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

    test-exclude-matches = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        child = {
          name = "drop";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.excludeAspect ref;
        comp = fx.send "resolve-include" child;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
      in
      {
        expr = builtins.isList result.value && (builtins.head result.value).meta.excluded;
        expected = true;
      }
    );

    test-exclude-no-match = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        child = {
          name = "keep";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.excludeAspect ref;
        comp = fx.send "resolve-include" child;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
      in
      {
        expr = (builtins.head result.value).name;
        expected = "keep";
      }
    );

    test-exclude-transitive = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "monitoring";
          meta = {
            provider = [ ];
          };
        };
        sub = {
          name = "node-exporter";
          meta = {
            provider = [ "monitoring" ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.excludeAspect ref;
        comp = fx.send "resolve-include" sub;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
      in
      {
        expr = (builtins.head result.value).meta.excluded;
        expected = true;
      }
    );

    test-substitute-replaces = denTest (
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
        child = {
          name = "old";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.substituteAspect ref replacement;
        comp = fx.send "resolve-include" child;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
        items = result.value;
      in
      {
        expr = {
          count = builtins.length items;
          firstExcluded = (builtins.elemAt items 0).meta.excluded;
          firstReplacedBy = (builtins.elemAt items 0).meta.replacedBy;
          secondName = (builtins.elemAt items 1).name;
        };
        expected = {
          count = 2;
          firstExcluded = true;
          firstReplacedBy = "new";
          secondName = "new";
        };
      }
    );

    test-substitute-no-match = denTest (
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
        child = {
          name = "keep";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.substituteAspect ref replacement;
        comp = fx.send "resolve-include" child;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
      in
      {
        expr = (builtins.head result.value).name;
        expected = "keep";
      }
    );

    test-moduleHandler-collects-imports = denTest (
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
                resume = [ param ];
                inherit state;
              };
          }
          // (fxLib.adapters.moduleHandler "nixos");
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
                resume = [ param ];
                inherit state;
              };
          }
          // fxLib.adapters.collectPathsHandler;
          state = {
            paths = [ ];
          };
        } comp;
      in
      {
        expr = builtins.length result.state.paths;
        expected = 1;
      }
    );

    test-moduleHandler-skips-tombstones = denTest (
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
                resume = [ param ];
                inherit state;
              };
          }
          // (fxLib.adapters.moduleHandler "nixos");
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

  };
}
