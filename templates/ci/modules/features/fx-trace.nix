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
  flake.tests.fx-trace = {

    test-structured-trace-fields = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        parent = {
          name = "root";
          meta = {
            provider = [ ];
          };
          nixos = {
            a = 1;
          };
          includes = [
            {
              name = "child";
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
        result =
          fxLib.resolve.mkPipeline
            {
              class = "nixos";
              extraHandlers = fxLib.adapters.structuredTraceHandler "nixos";
              extraState = {
                entries = [ ];
              };
            }
            {
              ctxNs = { };
              self = parent // {
                into = _: { };
                provides = { };
              };
              ctx = { };
            };
      in
      {
        expr = builtins.length result.state.entries >= 2;
        expected = true;
      }
    );

    test-trace-excluded-aspect = denTest (
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
            provider = [ ];
            adapter = fxLib.adapters.excludeAspect target;
          };
          includes = [
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
        result =
          fxLib.resolve.mkPipeline
            {
              class = "nixos";
              extraHandlers = fxLib.adapters.structuredTraceHandler "nixos";
              extraState = {
                entries = [ ];
              };
            }
            {
              ctxNs = { };
              self = parent // {
                into = _: { };
                provides = { };
              };
              ctx = { };
            };
        excluded = builtins.filter (e: e.excluded) result.state.entries;
      in
      {
        expr = builtins.length excluded >= 1;
        expected = true;
      }
    );

    test-ctx-trace-handler =
      let
        comp = fx.send "ctx-traverse" {
          key = "host";
          self = {
            name = "host";
            provides = { };
          };
          ctx = { };
          prev = null;
          prevCtx = null;
        };
        result = fx.handle {
          handlers."ctx-traverse" =
            { param, state }:
            let
              item = {
                key = param.key;
                selfName = param.self.name or "<anon>";
              };
            in
            {
              resume = null;
              state = state // {
                ctxTrace = (state.ctxTrace or [ ]) ++ [ item ];
              };
            };
          state = {
            ctxTrace = [ ];
          };
        } comp;
      in
      {
        expr = (builtins.head result.state.ctxTrace).key;
        expected = "host";
      };

    test-mkPipeline-with-trace = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        self = {
          name = "host";
          into = _: { };
          provides = { };
          nixos = {
            a = 1;
          };
          includes = [ ];
        };
        result =
          fxLib.resolve.mkPipeline
            {
              class = "nixos";
              extraHandlers = fxLib.adapters.structuredTraceHandler "nixos" // fxLib.handlers.ctxTraceHandler;
              extraState = {
                entries = [ ];
                ctxTrace = [ ];
              };
            }
            {
              ctxNs = { };
              inherit self;
              ctx = { };
            };
      in
      {
        expr = {
          hasEntries = builtins.length result.state.entries >= 1;
          hasImports = builtins.length result.state.imports >= 1;
        };
        expected = {
          hasEntries = true;
          hasImports = true;
        };
      }
    );

    # Provider results carry __ctxStage and __ctxKind tags.
    test-provider-stage-tagging = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        hostSelf = {
          name = "host";
          into = _: { };
          provides = {
            host = ctx: {
              name = "host-provider";
              meta = { };
              nixos = {
                fromProv = true;
              };
              includes = [ ];
            };
          };
          nixos = {
            base = true;
          };
          includes = [ ];
        };
        result =
          fxLib.resolve.mkPipeline
            {
              class = "nixos";
              extraHandlers = fxLib.adapters.structuredTraceHandler "nixos";
              extraState = {
                entries = [ ];
              };
            }
            {
              ctxNs = { };
              self = hostSelf;
              ctx = {
                host = "igloo";
              };
            };
        provEntries = builtins.filter (e: e.ctxKind == "self-provide") result.state.entries;
      in
      {
        expr = builtins.length provEntries >= 1;
        expected = true;
      }
    );

  };
}
