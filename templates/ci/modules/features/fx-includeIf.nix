{
  denTest,
  inputs,
  lib,
  ...
}:
let
  fx = inputs.nix-effects.lib;
  mkPassthroughHandlers =
    fxLib:
    {
      "resolve-include" =
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
    }
    // fxLib.handlers.adapterRegistryHandler
    // fxLib.adapters.pathSetHandler
    // fxLib.adapters.collectPathsHandler;
in
{
  flake.tests.fx-includeIf = {

    test-guard-passes-includes = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        target = {
          name = "feature";
          meta = {
            provider = [ ];
          };
          nixos = {
            a = 1;
          };
          includes = [ ];
        };
        guarded = fxLib.adapters.includeIf (_: true) [ target ];
        parent = {
          name = "root";
          meta = { };
          includes = [ guarded ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers = mkPassthroughHandlers fxLib;
          state = {
            adapterRegistry = { };
            paths = [ ];
          };
        } comp;
      in
      {
        expr = (builtins.head result.value.includes).name;
        expected = "feature";
      }
    );

    test-guard-fails-tombstones = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        target = {
          name = "feature";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        guarded = fxLib.adapters.includeIf (_: false) [ target ];
        parent = {
          name = "root";
          meta = { };
          includes = [ guarded ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers = mkPassthroughHandlers fxLib;
          state = {
            adapterRegistry = { };
            paths = [ ];
          };
        } comp;
      in
      {
        expr = (builtins.head result.value.includes).meta.excluded;
        expected = true;
      }
    );

    test-hasAspect-guard = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        sops = {
          name = "sops";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        sopsConf = {
          name = "sops-conf";
          meta = {
            provider = [ ];
          };
          nixos = {
            sops = true;
          };
          includes = [ ];
        };
        guarded = fxLib.adapters.includeIf (ctx: ctx.hasAspect sops) [ sopsConf ];
        parent = {
          name = "root";
          meta = { };
          includes = [
            sops
            guarded
          ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers = mkPassthroughHandlers fxLib;
          state = {
            adapterRegistry = { };
            paths = [ ];
          };
        } comp;
        names = map (c: c.name) result.value.includes;
      in
      {
        expr = builtins.elem "sops-conf" names;
        expected = true;
      }
    );

    test-hasAspect-guard-fails = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        sops = {
          name = "sops";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        sopsConf = {
          name = "sops-conf";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        guarded = fxLib.adapters.includeIf (ctx: ctx.hasAspect sops) [ sopsConf ];
        # sops is NOT in includes — guard should fail
        parent = {
          name = "root";
          meta = { };
          includes = [ guarded ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers = mkPassthroughHandlers fxLib;
          state = {
            adapterRegistry = { };
            paths = [ ];
          };
        } comp;
      in
      {
        expr = (builtins.head result.value.includes).meta.excluded;
        expected = true;
      }
    );

    test-fallback-pattern = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        sops = {
          name = "sops";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        sopsConf = {
          name = "sops-conf";
          meta = {
            provider = [ ];
          };
          nixos = { };
          includes = [ ];
        };
        ageConf = {
          name = "age-conf";
          meta = {
            provider = [ ];
          };
          nixos = { };
          includes = [ ];
        };
        parent = {
          name = "root";
          meta = { };
          includes = [
            sops
            (fxLib.adapters.includeIf (ctx: ctx.hasAspect sops) [ sopsConf ])
            (fxLib.adapters.includeIf (ctx: !ctx.hasAspect sops) [ ageConf ])
          ];
        };
        comp = fxLib.resolve.resolveDeepEffectful {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        result = fx.handle {
          handlers = mkPassthroughHandlers fxLib;
          state = {
            adapterRegistry = { };
            paths = [ ];
          };
        } comp;
        children = result.value.includes;
        names = map (c: c.name) children;
      in
      {
        expr = {
          hasSopsConf = builtins.elem "sops-conf" names;
          hasAgeConf = builtins.elem "age-conf" names;
          ageExcluded =
            (lib.findFirst (c: c.name == "~age-conf") { meta = { }; } children).meta.excluded or false;
        };
        expected = {
          hasSopsConf = true;
          hasAgeConf = false;
          ageExcluded = true;
        };
      }
    );

  };
}
