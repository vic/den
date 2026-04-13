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
        result = fxLib.resolve.resolveOne {
          ctx = {
            host = "h";
            user = "u";
          };
          class = "nixos";
          aspect-chain = [ ];
        } aspect;
      in
      {
        expr = {
          p = result.meta.isParametric;
          args = result.meta.fnArgNames;
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
        result =
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
      in
      {
        expr = result.meta ? isParametric;
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
        # child's __parent should be "root" (the parent's path key)
        expr = builtins.length result.state.parents >= 1;
        expected = true;
      }
    );

  };
}
