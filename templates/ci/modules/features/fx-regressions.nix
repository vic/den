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
  flake.tests.fx-regressions = {

    # #413/#423: Provider sub-aspect's includes contain parametric fns.
    # Old pipeline: context dropped during recursive descent.
    # Effects: each level independently sends what it needs.
    test-provider-sub-includes-get-context = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        inner =
          { host }:
          {
            nixos.networking.hostName = host;
          };
        provider = {
          name = "monitoring";
          meta = {
            provider = [ ];
          };
          includes = [ inner ];
        };
        result = fxLib.resolve.resolveDeep {
          ctx = {
            host = "igloo";
          };
          class = "nixos";
          aspect-chain = [ ];
        } provider;
        child = builtins.head result.includes;
      in
      {
        expr = child.nixos.networking.hostName;
        expected = "igloo";
      }
    );

    # #426: Static sub inside parametric parent. applyDeep dropped static subs.
    # Effects: static subs have no parametric args, body passes through.
    test-static-sub-preserves-owned = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        staticBase = {
          name = "base";
          meta = { };
          nixos = {
            programs.git.enable = true;
          };
          includes = [ ];
        };
        parametricDev = {
          name = "dev";
          meta = { };
          __functor =
            _:
            { user }:
            {
              includes = [ staticBase ];
            };
          __functionArgs = {
            user = false;
          };
          includes = [ ];
        };
        result = fxLib.resolve.resolveDeep {
          ctx = {
            user = "tux";
          };
          class = "nixos";
          aspect-chain = [ ];
        } parametricDev;
        child = builtins.head result.includes;
      in
      {
        expr = child.nixos.programs.git.enable;
        expected = true;
      }
    );

    # #437: Factory function resolved as static (pre-applied by user).
    test-factory-resolves-as-static = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        factoryResult = {
          name = "greeter";
          meta = { };
          nixos = {
            users.users.tux.description = "hello";
          };
          includes = [ ];
        };
        comp = fxLib.resolve.resolveOne {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } factoryResult;
        result = fx.handle {
          handlers =
            fxLib.handlers.staticHandler { class = "nixos"; aspect-chain = [ ]; };
          state = { };
        } comp;
      in
      {
        expr = result.value.nixos.users.users.tux.description;
        expected = "hello";
      }
    );

    # Meta carryover: meta.provider survives deep resolution.
    test-meta-provider-survives = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        child = {
          name = "sub";
          meta = {
            provider = [ "monitoring" ];
          };
          nixos = { };
          includes = [ ];
        };
        parent = {
          name = "monitoring";
          meta = {
            provider = [ ];
          };
          includes = [ child ];
        };
        result = fxLib.resolve.resolveDeep {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        childResult = builtins.head result.includes;
      in
      {
        expr = childResult.meta.provider;
        expected = [ "monitoring" ];
      }
    );

    # 3-level deep nesting with parametric at each level.
    test-three-level-deep-parametric = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        leaf =
          { host }:
          {
            nixos.networking.hostName = host;
          };
        mid = {
          name = "mid";
          meta = { };
          __functor =
            _:
            { user }:
            {
              includes = [ leaf ];
            };
          __functionArgs = {
            user = false;
          };
          includes = [ ];
        };
        root = {
          name = "root";
          meta = { };
          includes = [ mid ];
        };
        result = fxLib.resolve.resolveDeep {
          ctx = {
            host = "igloo";
            user = "tux";
          };
          class = "nixos";
          aspect-chain = [ ];
        } root;
        midResult = builtins.head result.includes;
        leafResult = builtins.head midResult.includes;
      in
      {
        expr = leafResult.nixos.networking.hostName;
        expected = "igloo";
      }
    );

  };
}
