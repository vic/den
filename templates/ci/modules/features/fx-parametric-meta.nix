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
  flake.tests.fx-parametric-meta = {

    test-parametric-has-meta = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        aspect = {
          name = "web";
          meta = { };
          __functor =
            _:
            { host, user }:
            {
              nixos = { };
            };
          __functionArgs = {
            host = false;
            user = false;
          };
          includes = [ ];
        };
        comp = fxLib.resolve.resolveOne {
          ctx = {
            host = "h";
            user = "u";
          };
          class = "nixos";
          aspect-chain = [ ];
        } aspect;
        result = fx.handle {
          handlers =
            fxLib.handlers.parametricHandler {
              host = "h";
              user = "u";
            }
            // fxLib.handlers.staticHandler {
              class = "nixos";
              aspect-chain = [ ];
            };
          state = { };
        } comp;
      in
      {
        expr = {
          p = result.value.meta.isParametric;
          args = result.value.meta.fnArgNames;
        };
        expected = {
          p = true;
          args = [
            "host"
            "user"
          ];
        };
      }
    );

    test-static-no-parametric-meta = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        comp =
          fxLib.resolve.resolveOne
            {
              ctx = { };
              class = "nixos";
              aspect-chain = [ ];
            }
            {
              name = "base";
              meta = { };
              nixos = { };
              includes = [ ];
            };
        result = fx.handle {
          handlers = fxLib.handlers.staticHandler {
            class = "nixos";
            aspect-chain = [ ];
          };
          state = { };
        } comp;
      in
      {
        expr = result.value.meta ? isParametric;
        expected = false;
      }
    );

    test-resolve-complete-has-parent = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        parent = {
          name = "root";
          meta = {
            provider = [ ];
          };
          includes = [
            {
              name = "child";
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
            "resolve-complete" =
              { param, state }:
              {
                resume = param;
                state = state // {
                  parents = (state.parents or [ ]) ++ [ (param.__parent or "ROOT") ];
                };
              };
          };
          state = {
            parents = [ ];
          };
        } comp;
      in
      {
        # child's __parent should be "root" (the parent's pathKey)
        expr = builtins.elem "root" result.state.parents;
        expected = true;
      }
    );

  };
}
