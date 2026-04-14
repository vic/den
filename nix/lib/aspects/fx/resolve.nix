{
  lib,
  den,
  fx,
  aspect,
  handlers,
  adapters,
  ctxApply,
  ...
}:
let
  inherit (aspect) wrapAspect;
  inherit (handlers) contextHandlers missingArgError;

  # Keys that are structural (part of the identity envelope),
  # not owned configuration.
  structuralKeys = [
    "includes"
    "__functor"
    "__functionArgs"
    "name"
    "meta"
  ];

  # Wrap a resolved body in the identity envelope.
  # Takes name/meta from the original aspectVal,
  # includes + owned config from the resolved body.
  wrapIdentity =
    { aspectVal, resolved }:
    let
      owned = removeAttrs resolved structuralKeys;
      includes = resolved.includes or [ ];
      meta = aspectVal.meta or { };
      fn = if aspectVal ? __functor then aspectVal.__functor aspectVal else null;
      isParametric = fn != null && lib.isFunction fn && lib.functionArgs fn != { };
      fnArgNames = if isParametric then builtins.attrNames (lib.functionArgs fn) else [ ];
    in
    {
      name = aspectVal.name or "<anon>";
      meta = {
        adapter = meta.adapter or null;
        provider = meta.provider or [ ];
      }
      // lib.optionalAttrs isParametric { inherit isParametric fnArgNames; };
      inherit includes;
    }
    // owned
    // lib.optionalAttrs (aspectVal ? __ctxStage) { inherit (aspectVal) __ctxStage; }
    // lib.optionalAttrs (aspectVal ? __ctxKind) { inherit (aspectVal) __ctxKind; }
    // lib.optionalAttrs (aspectVal ? __ctxAspect) { inherit (aspectVal) __ctxAspect; };

  # Resolve a single aspect against the given context.
  # Returns Computation (identity envelope). Effects bubble up.
  resolveOne =
    {
      ctx,
      class,
      aspect-chain,
    }:
    aspectVal:
    let
      fn = if aspectVal ? __functor then aspectVal.__functor aspectVal else null;
      isStatic = fn == null || !lib.isFunction fn;
    in
    if isStatic then
      fx.pure (wrapIdentity {
        inherit aspectVal;
        resolved = aspectVal;
      })
    else
      fx.bind (wrapAspect ctx fn) (
        resolved:
        fx.pure (wrapIdentity {
          inherit aspectVal;
          resolved = resolved;
        })
      );

  # Strict variant: uses rotate topology to detect missing context args.
  # Known effects are handled by rotate; unknowns are re-suspended.
  # After rotate, we check isPure — if not, the aspect requires an arg
  # not present in ctx, and we throw a diagnostic error.
  resolveOneStrict =
    {
      ctx,
      class,
      aspect-chain,
    }:
    aspectVal:
    let
      fn = if aspectVal ? __functor then aspectVal.__functor aspectVal else null;
      isStatic = fn == null || !lib.isFunction fn;
      aspectName = aspectVal.name or "<anon>";

      body =
        if isStatic then
          aspectVal
        else
          let
            comp = wrapAspect ctx fn;
            knownHandlers = contextHandlers { inherit ctx class aspect-chain; };

            # Inner: handle known context args, rotate unknowns outward
            rotated = fx.rotate {
              handlers = knownHandlers;
              state = { };
            } comp;

            errorForEffect = missingArgError { inherit ctx aspectName; };
          in
          if fx.isPure rotated then
            # All effects handled. rotated.value = { value; state; } from rotate's return clause.
            rotated.value.value
          else
            # Unhandled effect: the aspect needs something not in ctx.
            errorForEffect rotated.effect.name;
    in
    wrapIdentity {
      inherit aspectVal;
      resolved = body;
    };

  # Effectful tree walk. Returns Computation aspect.
  # Emits resolve-include before and resolve-complete after each child.
  # meta.adapter registers via register-adapter effect; check-exclusion
  # queries the registry for each child.
  resolveDeepEffectful =
    {
      ctx,
      class,
      aspect-chain ? [ ],
    }:
    let
      # Wrap bare function includes in an aspect envelope.
      wrapChild =
        child:
        if lib.isFunction child then
          {
            name = child.name or "<anon>";
            meta = child.meta or { };
            __functor = _: child;
            __functionArgs = lib.functionArgs child;
            includes = [ ];
          }
        else
          child;

      # Recursive resolution of a single aspect node.
      # parentPath tracks the parent's identity for __parent on resolve-complete.
      go =
        parentPath: aspectVal:
        fx.bind
          (
            (resolveOne {
              inherit ctx class;
              aspect-chain = [ ];
            })
            aspectVal
          )
          (
            resolved:
            let
              hasClassConfig = resolved ? ${class} && !(resolved.meta.excluded or false);
              identity = adapters.pathKey (adapters.aspectPath resolved);
              classEmit =
                if hasClassConfig then
                  fx.bind (fx.send "provide-class" {
                    inherit class identity;
                    module = resolved.${class};
                  }) (_: fx.pure null)
                else
                  fx.pure null;
              metaAdapter = resolved.meta.adapter or null;
              registerEmit =
                if metaAdapter != null then
                  fx.bind (fx.send "register-adapter" (metaAdapter // { owner = resolved.name or "<anon>"; })) (
                    _: fx.pure null
                  )
                else
                  fx.pure null;
              # Propagate ctx stage tags to children that don't have their own.
              # This ensures nested aspects inherit the context stage from their
              # declaring ancestor, matching the legacy structuredTrace behavior.
              parentStage = resolved.__ctxStage or null;
              parentKind = resolved.__ctxKind or null;
              parentCtxAspect = resolved.__ctxAspect or null;
              stageAttrs = {
                __ctxStage = parentStage;
                __ctxKind = parentKind;
                __ctxAspect = parentCtxAspect;
              };
              tagChild =
                child:
                if parentStage == null then
                  child
                else if builtins.isAttrs child then
                  if child ? __ctxStage then child else child // stageAttrs
                else if builtins.isFunction child then
                  {
                    name = child.name or "<anon>";
                    meta = child.meta or { };
                    __functor = _: child;
                    __functionArgs = lib.functionArgs child;
                    includes = [ ];
                  }
                  // stageAttrs
                else
                  child;
              includes = map tagChild (resolved.includes or [ ]);
              rawSelfPath = adapters.pathKey (adapters.aspectPath resolved);
              rawName = resolved.name or "<anon>";
              isMeaningful =
                rawName != "<anon>" && rawName != "<function body>" && !(lib.hasPrefix "[definition " rawName);
              selfPath = if isMeaningful then rawSelfPath else parentPath;
            in
            fx.bind classEmit (
              _:
              fx.bind registerEmit (
                _:
                resolveChildren selfPath includes (
                  resolvedIncludes: fx.pure (resolved // { includes = resolvedIncludes; })
                )
              )
            )
          );

      # Resolve a child: check-exclusion decides keep/exclude/substitute.
      # Conditional markers (includeIf) are handled separately.
      resolveChild =
        parentPath: parentIncludes: child:
        if builtins.isAttrs child && (child.meta.conditional or false) then
          resolveConditional parentPath parentIncludes child
        else
          let
            envelope = wrapChild child;
            childIdentity = adapters.pathKey (adapters.aspectPath envelope);
          in
          fx.bind (fx.send "check-exclusion" childIdentity) (
            decision:
            if decision.action == "exclude" then
              let
                ts = adapters.tombstone envelope { excludedFrom = decision.owner; };
              in
              fx.bind (fx.send "resolve-complete" (ts // { __parent = parentPath; })) (_: fx.pure [ ts ])
            else if decision.action == "substitute" then
              let
                ts = adapters.tombstone envelope {
                  excludedFrom = decision.owner;
                  replacedBy = decision.replacement.name or "<anon>";
                };
              in
              fx.bind (fx.send "resolve-complete" (ts // { __parent = parentPath; })) (
                _:
                fx.bind (go parentPath decision.replacement) (
                  resolvedReplacement:
                  fx.bind (fx.send "resolve-complete" (resolvedReplacement // { __parent = parentPath; })) (
                    _:
                    fx.pure [
                      ts
                      resolvedReplacement
                    ]
                  )
                )
              )
            else
              # Keep: emit resolve-include (for tracing), then recurse
              fx.bind (fx.send "resolve-include" envelope) (
                _:
                fx.bind (go parentPath envelope) (
                  resolvedChild:
                  fx.bind (fx.send "resolve-complete" (resolvedChild // { __parent = parentPath; })) (
                    _: fx.pure [ resolvedChild ]
                  )
                )
              )
          );

      # Evaluate a conditional marker against accumulated paths.
      resolveConditional =
        parentPath: parentIncludes: condNode:
        fx.bind (fx.send "get-path-set" null) (
          pathSet:
          let
            guardCtx = {
              hasAspect = ref: pathSet ? ${adapters.pathKey (adapters.aspectPath ref)};
            };
            pass = condNode.meta.guard guardCtx;
          in
          if pass then
            builtins.foldl' (
              acc: a:
              fx.bind acc (
                results:
                fx.bind (resolveChild parentPath parentIncludes a) (childResults: fx.pure (results ++ childResults))
              )
            ) (fx.pure [ ]) condNode.meta.aspects
          else
            builtins.foldl' (
              acc: a:
              fx.bind acc (
                results:
                let
                  ts = adapters.tombstone a { guardFailed = true; };
                in
                fx.bind (fx.send "resolve-complete" (ts // { __parent = parentPath; })) (
                  _: fx.pure (results ++ [ ts ])
                )
              )
            ) (fx.pure [ ]) condNode.meta.aspects
        );

      # Resolve all children.
      resolveChildren =
        parentPath: includes: cont:
        let
          childComp = builtins.foldl' (
            acc: child:
            fx.bind acc (
              results:
              fx.bind (resolveChild parentPath includes child) (childResults: fx.pure (results ++ childResults))
            )
          ) (fx.pure [ ]) includes;
        in
        fx.bind childComp cont;
    in
    go null;

  # Compose two handler sets, chaining handlers for shared effect names.
  # For overlapping keys, handler b runs first, then a's state updates are merged.
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

  # Default handler set for the full pipeline.
  defaultHandlers =
    { class, ctx }:
    handlers.parametricHandler ctx
    // handlers.staticHandler {
      inherit class;
      aspect-chain = [ ];
    }
    // handlers.ctxTraverseHandler
    // handlers.ctxSeenHandler
    // handlers.ctxProviderHandler
    // handlers.provideClassHandler
    // handlers.adapterRegistryHandler
    // adapters.pathSetHandler
    // {
      "resolve-include" =
        { param, state }:
        {
          resume = param;
          inherit state;
        };
      "resolve-complete" =
        { param, state }:
        let
          isExcluded = param.meta.excluded or false;
        in
        {
          resume = param;
          state = state // {
            paths = (state.paths or [ ]) ++ (lib.optional (!isExcluded) (adapters.aspectPath param));
          };
        };
    };

  defaultState = {
    seen = { };
    imports = [ ];
    adapterRegistry = { };
    paths = [ ];
  };

  # Configurable pipeline builder. Pass custom handlers/state to extend.
  mkPipeline =
    {
      extraHandlers ? { },
      extraState ? { },
      class,
    }:
    {
      ctxNs,
      self,
      ctx,
    }:
    let
      comp = fx.bind (ctxApply.ctxApplyEffectful ctxNs self ctx) (
        includes:
        fx.bind
          (resolveDeepEffectful
            {
              inherit ctx class;
              aspect-chain = [ ];
            }
            {
              name = self.name or "<anon>";
              meta = self.meta or { };
              inherit includes;
            }
          )
          (
            resolved:
            fx.bind (fx.send "resolve-complete" (resolved // { __parent = null; })) (_: fx.pure resolved)
          )
      );
    in
    fx.handle {
      # extraHandlers override defaultHandlers for same effect names.
      # Use tracingHandler (not separate structuredTraceHandler + collectPathsHandler)
      # to avoid // collisions on resolve-complete.
      handlers = composeHandlers (defaultHandlers { inherit class ctx; }) extraHandlers;
      state = defaultState // extraState;
    } comp;

  # Full pipeline: context traversal → resolution ��� module collection.
  # Implemented via mkPipeline with default handlers.
  fxFullResolve =
    {
      ctxNs,
      class,
      self,
      ctx,
    }:
    mkPipeline { inherit class; } { inherit ctxNs self ctx; };

  # Drop-in shape: returns { imports = [...] }
  fxResolve =
    args:
    let
      result = fxFullResolve args;
    in
    {
      imports = result.state.imports;
    };

  # Recursively resolve an aspect and all its includes.
  # Uses resolveOne by default. Pass strict = true to use resolveOneStrict
  # for diagnostic errors on missing context args.
  resolveDeep =
    {
      ctx,
      class,
      aspect-chain ? [ ],
      strict ? false,
    }:
    let
      resolveHandled =
        args: aspectVal:
        let
          comp = resolveOne args aspectVal;
          allHandlers = contextHandlers args;
          result = fx.handle {
            handlers = allHandlers;
            state = { };
          } comp;
        in
        result.value;
      resolve = if strict then resolveOneStrict else resolveHandled;
      go =
        chain: aspectVal:
        let
          resolved =
            (resolve {
              inherit ctx class;
              aspect-chain = chain;
            })
              aspectVal;
          newChain = chain ++ [ aspectVal ] ++ (lib.optional (aspectVal != resolved) resolved);
          resolvedIncludes = map (
            child:
            if lib.isFunction child then
              let
                childAspect = {
                  name = child.name or "<anon>";
                  meta = child.meta or { };
                  __functor = _: child;
                  __functionArgs = lib.functionArgs child;
                  includes = [ ];
                };
              in
              go newChain childAspect
            else if builtins.isAttrs child && child ? name then
              go newChain child
            else
              child
          ) (resolved.includes or [ ]);
        in
        resolved // { includes = resolvedIncludes; };
    in
    go aspect-chain;

in
{
  inherit
    resolveOne
    resolveOneStrict
    resolveDeep
    resolveDeepEffectful
    fxFullResolve
    fxResolve
    mkPipeline
    defaultHandlers
    defaultState
    composeHandlers
    wrapIdentity
    ;
}
