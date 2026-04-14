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
        # root + child = 2 entries (root via mkPipeline's resolve-complete, child during walk)
        expr =
          let
            names = map (e: e.name) result.state.entries;
          in
          {
            hasRoot = builtins.elem "root" names;
            hasChild = builtins.elem "child" names;
            allHaveClass = builtins.all (e: e.class == "nixos") result.state.entries;
          };
        expected = {
          hasRoot = true;
          hasChild = true;
          allHaveClass = true;
        };
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
        expr =
          let
            excludedNames = map (e: e.name) excluded;
          in
          {
            hasExcluded = builtins.elem "~drop" excludedNames;
            excludedFromSet = (builtins.head excluded).excludedFrom != null;
          };
        expected = {
          hasExcluded = true;
          excludedFromSet = true;
        };
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
          hasHostEntry = builtins.any (e: e.name == "host") result.state.entries;
          allEntriesHaveClass = builtins.all (e: e.class == "nixos") result.state.entries;
          hasImports = result.state.imports != [ ];
          hasCtxTrace = builtins.elem "host" (map (t: t.key) (result.state.ctxTrace or [ ]));
        };
        expected = {
          hasHostEntry = true;
          allEntriesHaveClass = true;
          hasImports = true;
          hasCtxTrace = true;
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
        expr =
          let
            provNames = map (e: e.name) provEntries;
          in
          {
            hasProvider = builtins.elem "host-provider" provNames;
            kindCorrect = (builtins.head provEntries).ctxKind == "self-provide";
          };
        expected = {
          hasProvider = true;
          kindCorrect = true;
        };
      }
    );

    # tracingHandler collects entries + paths (but not imports) via resolve-complete.
    # composeHandlers chains it with moduleHandler for imports.
    test-tracingHandler-collects-entries-and-paths = denTest (
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
              extraHandlers = fxLib.adapters.tracingHandler "nixos" // fxLib.handlers.ctxTraceHandler;
              extraState = {
                entries = [ ];
                paths = [ ];
                ctxTrace = [ ];
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
        expr = {
          hasEntries = result.state.entries != [ ];
          hasPaths = result.state.paths != [ ];
          hasImports = result.state.imports != [ ];
        };
        expected = {
          hasEntries = true;
          hasPaths = true;
          hasImports = true;
        };
      }
    );

    # ctxTraceHandler produces items with ctxKeys, entityNames, provideNames.
    test-ctxTraceHandler-full-fields = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        self = {
          name = "host";
          into = _: { };
          provides = {
            host = _: { };
          };
        };
        comp = fxLib.ctxApply.ctxApplyEffectful { } self { host = "igloo"; };
        result = fx.handle {
          handlers =
            fxLib.handlers.ctxTraceHandler
            // fxLib.handlers.ctxSeenHandler
            // fxLib.handlers.ctxProviderHandler;
          state = {
            seen = { };
            ctxTrace = [ ];
          };
        } comp;
        firstItem = builtins.head result.state.ctxTrace;
      in
      {
        expr = {
          hasCtxKeys = firstItem ? ctxKeys;
          hasEntityNames = firstItem ? entityNames;
          hasProvideNames = firstItem ? provideNames;
          ctxKeysHasHost = builtins.elem "host" (firstItem.ctxKeys or [ ]);
        };
        expected = {
          hasCtxKeys = true;
          hasEntityNames = true;
          hasProvideNames = true;
          ctxKeysHasHost = true;
        };
      }
    );

  };
}
