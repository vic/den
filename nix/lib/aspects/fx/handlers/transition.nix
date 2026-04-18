# into-transition handler — processes context transitions with scoped sub-computations.
# Handles: into-transition
# Sends: ctx-seen (dedup), resolve-complete (missing transition tombstone),
#        then aspectToEffect in scoped constantHandler(parentCtx // newCtx)
# Cross-providers: if source.provides.${targetKey} exists, it's resolved alongside the target.
# State reads: currentCtx
# External dependency: den.ctx (context aspect registry, looked up by transition path)
{
  lib,
  den,
  ...
}:
let
  fx = den.lib.fx;
  inherit (den.lib.aspects.fx.handlers) constantHandler includeHandler;
  inherit (den.lib.aspects.fx.aspect) aspectToEffect;

  # Flatten a nested into attrset into a flat list of { path, contexts }.
  flattenInto =
    attrset: prefix:
    lib.concatLists (
      lib.mapAttrsToList (
        name: v:
        let
          path = prefix ++ [ name ];
        in
        if builtins.isList v then
          [
            {
              inherit path;
              contexts = v;
            }
          ]
        else
          flattenInto v path
      ) attrset
    );

  # Build a scoped into-transition handler that uses scopedCtx directly
  # instead of reading state.currentCtx (which is the root ctx).
  mkScopedTransitionHandler = scopedCtx: {
    "into-transition" =
      { param, state }:
      let
        sourceAspect = param.self;
        _ts = builtins.trace "scopedTransitionHandler: source=${sourceAspect.name or "?"} scopedCtx=${toString (builtins.attrNames scopedCtx)}";
        intoResult = _ts (param.intoFn scopedCtx);
        transitions = flattenInto intoResult [ ];
      in
      {
        resume = builtins.foldl' (
          acc: transition: fx.bind acc (r: resolveTransition sourceAspect scopedCtx r transition)
        ) (fx.pure [ ]) transitions;
        inherit state;
      };
  };

  # Resolve a single context value by running aspectToEffect in a scoped handler.
  # Installs constantHandler (for bind.fn arg resolution) and a scoped
  # into-transition handler (so nested transitions use scopedCtx, not root state).
  resolveContextValue =
    parentCtx: targetAspect: results: newCtx:
    let
      scopedCtx = parentCtx // newCtx;
      _t = builtins.trace "resolveContextValue: target=${targetAspect.name or "?"} scopedCtx=${toString (builtins.attrNames scopedCtx)}";
    in
    _t (
      # Push scoped args so keepChild knows what's available, then pop after.
      fx.bind (fx.send "push-scope-args" scopedCtx) (
        _:
        fx.bind
          (fx.effects.scope.run {
            # Include includeHandler so emit-include is handled INSIDE the scope
            # where constantHandler has the right context. Without this, emit-include
            # rotates to the outer handler where context args are missing.
            handlers = constantHandler scopedCtx // mkScopedTransitionHandler scopedCtx // includeHandler;
          } (aspectToEffect targetAspect))
          (childResult: fx.bind (fx.send "pop-scope-args" null) (_: fx.pure (results ++ [ childResult ])))
      )
    );

  # Resolve a single transition: look up target aspect, check dedup, resolve each context value.
  # Also emits cross-providers: if sourceAspect.provides.${targetKey} exists,
  # that provider is resolved in the scoped context (e.g. flake-system.provides.flake-packages).
  resolveTransition =
    sourceAspect: currentCtx: results: transition:
    let
      key = lib.concatStringsSep "/" transition.path;
      targetKey = lib.last transition.path;
      targetAspect = lib.attrByPath transition.path null (den.ctx or { });
      sourceProvides = sourceAspect.provides or { };
      crossProvider = sourceProvides.${targetKey} or null;
      _t = builtins.trace "resolveTransition: ${sourceAspect.name or "?"} → ${key} crossProvider=${
        toString (crossProvider != null)
      } sourceProvides=${toString (builtins.attrNames sourceProvides)}";
      # Emit cross-provider result in a scoped context.
      # Resolve directly via aspectToEffect inside scope.run (not emit-include,
      # which would rotate to outer scope and lose the scoped context).
      emitCrossProvider =
        scopedCtx: prevResults:
        if crossProvider != null then
          let
            crossResult = crossProvider scopedCtx;
            # Wrap bare functions as parametric aspects for aspectToEffect.
            wrapped =
              if lib.isFunction crossResult && !builtins.isAttrs crossResult then
                {
                  name = "${sourceAspect.name or "?"}.provides.${targetKey}";
                  meta = { };
                  __functor = _: crossResult;
                  __functionArgs = lib.functionArgs crossResult;
                  includes = [ ];
                }
              else
                crossResult;
            _tc = builtins.trace "cross-provide: ${sourceAspect.name or "?"} → ${targetKey} ctx=${toString (builtins.attrNames scopedCtx)} wrapped=${wrapped.name or "?"}";
          in
          _tc (
            fx.bind (fx.effects.scope.run {
              handlers = constantHandler scopedCtx // mkScopedTransitionHandler scopedCtx;
            } (aspectToEffect wrapped)) (crossResolved: fx.pure (prevResults ++ [ crossResolved ]))
          )
        else
          fx.pure prevResults;
    in
    _t (
      if targetAspect == null && crossProvider == null then
        # No target ctx node and no cross-provider — emit tombstone.
        let
          ts = {
            name = "~<missing-transition:${key}>";
            meta = {
              excluded = true;
              transitionMissing = true;
              transitionPath = key;
            };
            includes = [ ];
          };
        in
        fx.bind (fx.send "resolve-complete" ts) (_: fx.pure (results ++ [ ts ]))
      else
        fx.bind (fx.send "ctx-seen" key) (
          { isFirst }:
          let
            _ts = builtins.trace "ctx-seen: ${key} isFirst=${toString isFirst}";
          in
          _ts (
            if !isFirst then
              fx.pure results
            else
              builtins.foldl' (
                acc: newCtx:
                fx.bind acc (
                  innerResults:
                  let
                    scopedCtx = currentCtx // newCtx;
                    # Resolve target ctx node if it exists.
                    withTarget =
                      if targetAspect != null then
                        resolveContextValue currentCtx targetAspect innerResults newCtx
                      else
                        fx.pure innerResults;
                  in
                  fx.bind withTarget (targetResults: emitCrossProvider scopedCtx targetResults)
                )
              ) (fx.pure results) transition.contexts
          )
        )
    );

  transitionHandler = {
    "into-transition" =
      { param, state }:
      let
        sourceAspect = param.self;
        # currentCtx is wrapped in a thunk (_: ctx) to survive deepSeq.
        currentCtx = (state.currentCtx or (_: { })) null;
        _t = builtins.trace "transitionHandler: source=${sourceAspect.name or "?"} currentCtx=${toString (builtins.attrNames currentCtx)} intoFn?=${toString (param ? intoFn)}";
        intoResult = _t (param.intoFn currentCtx);
        transitions = flattenInto intoResult [ ];
        transitionKeys = map (t: lib.concatStringsSep "/" t.path) transitions;
        _t2 = builtins.trace "transitionHandler: ${toString (builtins.length transitions)} transitions: ${toString transitionKeys}";
      in
      _t2 {
        resume = builtins.foldl' (
          acc: transition: fx.bind acc (results: resolveTransition sourceAspect currentCtx results transition)
        ) (fx.pure [ ]) transitions;
        inherit state;
      };
  };

in
{
  inherit transitionHandler;
}
