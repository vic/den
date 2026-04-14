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
  flake.tests.fx-effectful-resolve = {

    # Basic: no adapters, passthrough handlers, result matches structure.
    test-basic-effectful = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        parent = {
          name = "parent";
          meta = { };
          nixos = {
            a = 1;
          };
          includes = [
            {
              name = "child";
              meta = { };
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
            "resolve-complete" =
              { param, state }:
              {
                resume = param;
                inherit state;
              };
            "provide-class" =
              { param, state }:
              {
                resume = null;
                inherit state;
              };
          };
          state = { };
        } comp;
      in
      {
        expr = {
          parentName = result.value.name;
          childName = (builtins.head result.value.includes).name;
          childB = (builtins.head result.value.includes).nixos.b;
        };
        expected = {
          parentName = "parent";
          childName = "child";
          childB = 2;
        };
      }
    );

    # Adapter: meta.adapter excludes a child via scoped rotate.
    test-adapter-excludes-child = denTest (
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
          name = "parent";
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
            "resolve-complete" =
              { param, state }:
              {
                resume = param;
                inherit state;
              };
            "provide-class" =
              { param, state }:
              {
                resume = null;
                inherit state;
              };
          };
          state = { };
        } comp;
        children = result.value.includes;
      in
      {
        expr = {
          count = builtins.length children;
          firstName = (builtins.elemAt children 0).name;
          secondExcluded = (builtins.elemAt children 1).meta.excluded;
        };
        expected = {
          count = 2;
          firstName = "keep";
          secondExcluded = true;
        };
      }
    );

    # resolve-complete fires for each resolved child, state accumulates.
    test-resolve-complete-collects = denTest (
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
            "resolve-complete" =
              { param, state }:
              {
                resume = param;
                state = state // {
                  names = (state.names or [ ]) ++ [ param.name ];
                };
              };
          };
          state = {
            names = [ ];
          };
        } comp;
      in
      {
        expr = result.state.names;
        expected = [
          "a"
          "b"
        ];
      }
    );

    # Parametric child resolved through effectful path.
    test-parametric-child-effectful = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        parent = {
          name = "root";
          meta = { };
          includes = [
            {
              name = "web";
              meta = { };
              __functor =
                _:
                { host }:
                {
                  nixos.hostName = host;
                };
              __functionArgs = {
                host = false;
              };
              includes = [ ];
            }
          ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = {
            host = "igloo";
          };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers =
            fxLib.handlers.parametricHandler { host = "igloo"; }
            // fxLib.handlers.staticHandler {
              class = "nixos";
              aspect-chain = [ ];
            }
            // {
              "resolve-include" =
                { param, state }:
                {
                  resume = [ param ];
                  inherit state;
                };
              "resolve-complete" =
                { param, state }:
                {
                  resume = param;
                  inherit state;
                };
              "provide-class" =
                { param, state }:
                {
                  resume = null;
                  inherit state;
                };
            };
          state = { };
        } comp;
        child = builtins.head result.value.includes;
      in
      {
        expr = child.nixos.hostName;
        expected = "igloo";
      }
    );

    # Bare function include gets wrapped in envelope.
    test-bare-function-wrapped = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        parent = {
          name = "root";
          meta = { };
          includes = [
            (
              { host }:
              {
                nixos.hostName = host;
              }
            )
          ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = {
            host = "igloo";
          };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers =
            fxLib.handlers.parametricHandler { host = "igloo"; }
            // fxLib.handlers.staticHandler {
              class = "nixos";
              aspect-chain = [ ];
            }
            // {
              "resolve-include" =
                { param, state }:
                {
                  resume = [ param ];
                  inherit state;
                };
              "resolve-complete" =
                { param, state }:
                {
                  resume = param;
                  inherit state;
                };
              "provide-class" =
                { param, state }:
                {
                  resume = null;
                  inherit state;
                };
            };
          state = { };
        } comp;
        child = builtins.head result.value.includes;
      in
      {
        expr = child.nixos.hostName;
        expected = "igloo";
      }
    );

    # Nested adapters: inner excludes B, outer excludes A — both tombstoned.
    test-nested-adapter-override = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        targetA = {
          name = "A";
          meta = {
            provider = [ ];
          };
        };
        targetB = {
          name = "B";
          meta = {
            provider = [ ];
          };
        };
        parent = {
          name = "root";
          meta = {
            adapter = fxLib.adapters.excludeAspect targetA;
          };
          includes = [
            {
              name = "inner";
              meta = {
                adapter = fxLib.adapters.excludeAspect targetB;
              };
              includes = [
                {
                  name = "B";
                  meta = {
                    provider = [ ];
                  };
                  nixos = {
                    b = 1;
                  };
                  includes = [ ];
                }
              ];
            }
            {
              name = "A";
              meta = {
                provider = [ ];
              };
              nixos = {
                a = 1;
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
            "resolve-complete" =
              { param, state }:
              {
                resume = param;
                state = state // {
                  excluded = (state.excluded or [ ]) ++ (lib.optional (param.meta.excluded or false) param.name);
                };
              };
          };
          state = {
            excluded = [ ];
          };
        } comp;
      in
      {
        expr = builtins.sort builtins.lessThan result.state.excluded;
        expected = [
          "~A"
          "~B"
        ];
      }
    );

  };
}
