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
    // owned;

  # Resolve a single aspect against the given context.
  # Static aspects pass through directly.
  # Parametric aspects (with __functor) are interpreted via fx.handle.
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

      body =
        if isStatic then
          aspectVal
        else
          let
            comp = wrapAspect ctx fn;
            allHandlers = contextHandlers { inherit ctx class aspect-chain; };
            result = fx.handle {
              handlers = allHandlers;
              state = { };
            } comp;
          in
          result.value;
    in
    wrapIdentity {
      inherit aspectVal;
      resolved = body;
    };

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
  # meta.adapter on an aspect installs scoped handler via fx.rotate.
  resolveDeepEffectful =
    {
      ctx,
      class,
      aspect-chain ? [ ],
      strict ? false,
    }:
    let
      resolve = if strict then resolveOneStrict else resolveOne;

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
      # aspect-chain grows at each level, matching existing pipeline behavior.
      # parentPath tracks the parent's identity for __parent on resolve-complete.
      go =
        chain: parentPath: aspectVal:
        let
          resolved =
            (resolve {
              inherit ctx class;
              aspect-chain = chain;
            })
              aspectVal;
          newChain = chain ++ [ aspectVal ] ++ (lib.optional (aspectVal != resolved) resolved);
          metaAdapter = resolved.meta.adapter or null;
          includes = resolved.includes or [ ];
          selfPath = adapters.pathKey (adapters.aspectPath resolved);
        in
        resolveChildren newChain selfPath metaAdapter includes (
          resolvedIncludes: fx.pure (resolved // { includes = resolvedIncludes; })
        );

      # Emit resolve-include for a child, then process the response list.
      # Conditional markers (includeIf) are handled separately.
      resolveChild =
        chain: parentPath: parentIncludes: child:
        if builtins.isAttrs child && (child.meta.conditional or false) then
          resolveConditional chain parentPath parentIncludes child
        else
          let
            envelope = wrapChild child;
          in
          fx.bind (fx.send "resolve-include" envelope) (
            approvedList: processApproved chain parentPath approvedList
          );

      # Evaluate a conditional marker against the raw includes tree.
      resolveConditional =
        chain: parentPath: parentIncludes: condNode:
        let
          rawPaths = adapters.collectRawPaths parentIncludes;
          rawPathSet = adapters.toPathSet rawPaths;
          guardCtx = {
            hasAspect = ref: rawPathSet ? ${adapters.pathKey (adapters.aspectPath ref)};
          };
          pass = condNode.meta.guard guardCtx;
        in
        if pass then
          # Include guarded aspects normally
          builtins.foldl' (
            acc: a:
            fx.bind acc (
              results:
              fx.bind (fx.send "resolve-include" a) (
                approved:
                fx.bind (processApproved chain parentPath approved) (processed: fx.pure (results ++ processed))
              )
            )
          ) (fx.pure [ ]) condNode.meta.aspects
        else
          # Tombstone all guarded aspects
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
          ) (fx.pure [ ]) condNode.meta.aspects;

      # Process a list of approved children (supports substitution [tombstone, replacement]).
      processApproved =
        chain: parentPath: children:
        builtins.foldl' (
          acc: child:
          fx.bind acc (
            results:
            if child == null then
              fx.pure results
            else if child.meta.excluded or false then
              # Tombstoned: emit resolve-complete but don't recurse
              fx.bind (fx.send "resolve-complete" (child // { __parent = parentPath; })) (
                _: fx.pure (results ++ [ child ])
              )
            else
              # Live child: recurse, then emit resolve-complete
              fx.bind (go chain parentPath child) (
                resolvedChild:
                fx.bind (fx.send "resolve-complete" (resolvedChild // { __parent = parentPath; })) (
                  _: fx.pure (results ++ [ resolvedChild ])
                )
              )
          )
        ) (fx.pure [ ]) children;

      # Resolve all children. If meta.adapter present, install scoped handler via rotate.
      resolveChildren =
        chain: parentPath: metaAdapter: includes: cont:
        let
          childComp = builtins.foldl' (
            acc: child:
            fx.bind acc (
              results:
              fx.bind (resolveChild chain parentPath includes child) (
                childResults: fx.pure (results ++ childResults)
              )
            )
          ) (fx.pure [ ]) includes;
        in
        if metaAdapter != null then
          # Install scoped adapter handler. Rotate handles resolve-include,
          # unknown effects (context args, resolve-complete) pass through.
          fx.bind (fx.rotate {
            handlers = metaAdapter;
            state = { };
          } childComp) (rotateResult: cont rotateResult.value)
        else
          fx.bind childComp cont;
    in
    go aspect-chain null;

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
    class:
    handlers.ctxTraverseHandler
    // handlers.ctxSeenHandler
    // handlers.ctxProviderHandler
    // {
      "resolve-include" =
        { param, state }:
        {
          resume = [ param ];
          inherit state;
        };
    }
    // (adapters.moduleHandler class);

  defaultState = {
    seen = { };
    imports = [ ];
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
      handlers = composeHandlers (defaultHandlers class) extraHandlers;
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
      resolve = if strict then resolveOneStrict else resolveOne;
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
