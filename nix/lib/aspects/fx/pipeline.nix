{
  lib,
  den,
  ...
}:
let
  fx = den.lib.fx;
  handlers = den.lib.aspects.fx.handlers;
  identity = den.lib.aspects.fx.identity;
  inherit (den.lib.aspects.fx.aspect) aspectToEffect;

  # Compose two handler sets, chaining handlers for shared effect names.
  # For overlapping keys: b's resume wins, a's state wins (a runs on b's output state).
  #
  # IMPORTANT LIMITATIONS:
  # 1. Composed handlers MUST NOT write to the same state keys — a runs on b's output
  #    state so shared keys would double-append.
  # 2. When b returns an effectful resume (computation), the sub-computation runs with
  #    b's state, not a's. State changes from a are lost for the duration of the
  #    sub-computation. Only correct when a does not produce effectful resumes for
  #    shared effect names.
  #
  # Designed for the tracing use case: tracingHandler (b) controls resume,
  # defaultHandlers (a) accumulates paths/imports. Both constraints hold for this case.
  composeHandlers =
    a: b:
    let
      shared = builtins.intersectAttrs a b;
      sharedComposed = builtins.mapAttrs (
        name: _:
        { param, state }:
        let
          rb = b.${name} { inherit param state; };
          ra = a.${name} {
            inherit param;
            state = rb.state;
          };
        in
        {
          resume = rb.resume;
          state = ra.state;
        }
      ) shared;
    in
    a // b // sharedComposed;

  # Default handler set for the unified pipeline.
  defaultHandlers =
    { class, ctx }:
    handlers.constantHandler (
      {
        inherit class;
        "aspect-chain" = [ ];
      }
      // ctx
    )
    // handlers.classCollectorHandler { targetClass = class; }
    // handlers.constraintRegistryHandler
    // handlers.chainHandler
    // handlers.includeHandler
    // handlers.transitionHandler
    // handlers.ctxSeenHandler
    // identity.pathSetHandler
    // identity.collectPathsHandler
    // fx.effects.state.handler;

  defaultState = {
    seen = { };
    # Thunk chain (not a list) so trampoline's deepSeq on state doesn't
    # force NixOS config objects. Unwrap with `state.imports null`.
    imports = _: [ ];
    constraintRegistry = { };
    constraintFilters = [ ];
    paths = [ ];
    pathSet = { };
    includesChain = [ ];
  };

  # Configurable pipeline builder. Runs aspectToEffect on the root aspect
  # with the full handler set.
  mkPipeline =
    {
      extraHandlers ? { },
      extraState ? { },
      class,
    }:
    {
      self,
      ctx,
    }:
    let
      comp = aspectToEffect self;
      # Override aspect-chain to include root aspect — consumed by provider
      # functions (home-env.nix) via bind.fn.
      rootHandlers = defaultHandlers {
        inherit class;
        ctx = ctx // {
          "aspect-chain" = [ self ];
        };
      };
    in
    fx.handle {
      handlers = composeHandlers rootHandlers extraHandlers;
      # Wrap currentCtx in a thunk (function) so the trampoline's
      # builtins.deepSeq on state doesn't force the NixOS config objects
      # inside ctx (which would eagerly evaluate optional input defaults
      # like hjem.module).
      state =
        defaultState
        // extraState
        // {
          currentCtx = _: ctx;
        };
    } comp;

  # Full pipeline: aspect compilation → handler-driven resolution → module collection.
  # Returns raw fx.handle result with { value, state }.
  fxFullResolve =
    {
      class,
      self,
      ctx,
    }:
    mkPipeline { inherit class; } { inherit self ctx; };

  # Drop-in resolve shape: returns { imports = [...] }.
  fxResolve =
    {
      class,
      self,
      ctx,
    }:
    let
      result = mkPipeline { inherit class; } { inherit self ctx; };
    in
    {
      imports = result.state.imports null;
    };
in
{
  inherit
    composeHandlers
    defaultHandlers
    defaultState
    mkPipeline
    fxFullResolve
    fxResolve
    ;
}
