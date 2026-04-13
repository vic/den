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
    in
    {
      name = aspectVal.name or "<anon>";
      meta = {
        adapter = meta.adapter or null;
        provider = meta.provider or [ ];
      };
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
      aspect-chain,
      strict ? false,
    }:
    let
      resolver = (if strict then resolveOneStrict else resolveOne) { inherit ctx class aspect-chain; };

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
      go =
        aspectVal:
        let
          resolved = resolver aspectVal;
          metaAdapter = resolved.meta.adapter or null;
          includes = resolved.includes or [ ];
        in
        resolveChildren metaAdapter includes (
          resolvedIncludes: fx.pure (resolved // { includes = resolvedIncludes; })
        );

      # Emit resolve-include for a child, then process the response list.
      # Conditional markers (includeIf) are handled separately.
      resolveChild =
        parentIncludes: child:
        if builtins.isAttrs child && (child.meta.conditional or false) then
          resolveConditional parentIncludes child
        else
          let
            envelope = wrapChild child;
          in
          fx.bind (fx.send "resolve-include" envelope) (approvedList: processApproved approvedList);

      # Evaluate a conditional marker against the raw includes tree.
      resolveConditional =
        parentIncludes: condNode:
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
                approved: fx.bind (processApproved approved) (processed: fx.pure (results ++ processed))
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
              fx.bind (fx.send "resolve-complete" ts) (_: fx.pure (results ++ [ ts ]))
            )
          ) (fx.pure [ ]) condNode.meta.aspects;

      # Process a list of approved children (supports substitution [tombstone, replacement]).
      processApproved =
        children:
        builtins.foldl' (
          acc: child:
          fx.bind acc (
            results:
            if child == null then
              fx.pure results
            else if child.meta.excluded or false then
              # Tombstoned: emit resolve-complete but don't recurse
              fx.bind (fx.send "resolve-complete" child) (_: fx.pure (results ++ [ child ]))
            else
              # Live child: recurse, then emit resolve-complete
              fx.bind (go child) (
                resolvedChild:
                fx.bind (fx.send "resolve-complete" resolvedChild) (_: fx.pure (results ++ [ resolvedChild ]))
              )
          )
        ) (fx.pure [ ]) children;

      # Resolve all children. If meta.adapter present, install scoped handler via rotate.
      resolveChildren =
        metaAdapter: includes: cont:
        let
          childComp = builtins.foldl' (
            acc: child:
            fx.bind acc (
              results: fx.bind (resolveChild includes child) (childResults: fx.pure (results ++ childResults))
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
    go;

  # Full pipeline: context traversal → resolution → module collection.
  # Returns { value = resolvedTree; state = { seen; imports; }; }
  fxFullResolve =
    {
      ctxNs,
      class,
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
            # Emit resolve-complete for root so moduleHandler collects root's class module
            fx.bind (fx.send "resolve-complete" resolved) (_: fx.pure resolved)
          )
      );
    in
    fx.handle {
      handlers =
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
      state = {
        seen = { };
        imports = [ ];
      };
    } comp;

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
      aspect-chain,
      strict ? false,
    }:
    let
      resolver = (if strict then resolveOneStrict else resolveOne) { inherit ctx class aspect-chain; };
      go =
        aspectVal:
        let
          resolved = resolver aspectVal;
          resolvedIncludes = map (
            child:
            if lib.isFunction child then
              # Bare function include (e.g. { host, ... }: { ... }) — wrap
              # in a minimal aspect envelope so resolveOne can handle it.
              let
                childAspect = {
                  name = child.name or "<anon>";
                  meta = child.meta or { };
                  __functor = _: child;
                  __functionArgs = lib.functionArgs child;
                  includes = [ ];
                };
              in
              go childAspect
            else if builtins.isAttrs child && child ? name then
              # Named aspect (has envelope shape) — recurse
              go child
            else if builtins.isAttrs child then
              # Plain attrset config — pass through
              child
            else
              # Shouldn't happen in well-formed trees, but pass through
              child
          ) (resolved.includes or [ ]);
        in
        resolved // { includes = resolvedIncludes; };
    in
    go;

in
{
  inherit
    resolveOne
    resolveOneStrict
    resolveDeep
    resolveDeepEffectful
    fxFullResolve
    fxResolve
    wrapIdentity
    ;
}
