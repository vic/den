{ lib, den, ... }:
let
  inherit (den.lib) take canTake;
  inherit (den.lib.statics) owned statics isCtxStatic;

  # Preserve aspect identity through functor evaluation.
  # Carries name and typed meta options so adapters and provenance
  # survive, without leaking freeform user meta to child results.
  withIdentity =
    self: extra:
    let
      meta = self.meta or { };
    in
    {
      name = self.name or "<anon>";
      meta = {
        adapter = meta.adapter or null;
        handleWith = meta.handleWith or null;
        excludes = meta.excludes or [ ];
        provider = meta.provider or [ ];
      };
    }
    // extra;

  # Copy fn's meta onto a materialized functor result. Preserves
  # meta.provider so provider sub-aspects keep their full aspectPath
  # (e.g. ["foo","sub"]) after the user fn is invoked and returns a
  # raw attrset that would otherwise drop it.
  carryMeta =
    fn: result:
    if builtins.isAttrs result && fn ? meta && !(result ? meta) then
      result // { inherit (fn) meta; }
    else
      result;

  # When takeFn succeeds and returns a result with sub-includes,
  # also try to resolve those sub-includes with takeFn. This handles
  # provider sub-aspect functions nested inside include results:
  # e.g. wrapped_fn returns { includes = [foo.provides.sub]; } where foo.provides.sub
  # needs parametric context applied before reaching the static pipeline.
  applyDeep =
    takeFn: ctx: fn:
    let
      rRaw = takeFn fn ctx;
      r = carryMeta fn rRaw;
      # Bare provider results carry only includes (+ name from carryAttrs).
      # Results from withOwn/withIdentity have meta; deferred deepRecurse
      # wrappers have __functor. Re-resolving either would double-apply
      # context and duplicate modules.
      # Checked against rRaw (pre-carryMeta) so the recursion branch still fires.
      isBareResult = builtins.isAttrs rRaw && rRaw ? includes && !(rRaw ? meta) && !(rRaw ? __functor);
    in
    if rRaw == { } then
      rRaw
    else if isBareResult then
      r
      // {
        # Only recurse into subs whose functor actually consumes this ctx.
        # A static aspect's default functor takes a bare `ctx` (functionArgs
        # = {}), so canTake.upTo is false and we leave it alone — its owned
        # class configs must be picked up later by the static resolve pass.
        # A user-provided provider fn (e.g. { host, ... }: { nixos = ...; })
        # has host in functionArgs; canTake.upTo fires and we materialize it.
        #
        # Named aspects (coerced from parametric fns by coercedProviderType)
        # also have functionArgs = {} on their default functor, so
        # canTake.upTo fails for them too. But their includes may contain
        # unapplied parametric functions that need context. For these, recurse
        # into the aspect's includes directly — applying context to each fn
        # include without invoking the aspect's own functor (which would drop
        # owned class configs on static aspects per #423).
        includes = map (
          sub:
          if canTake.upTo ctx sub then
            carryMeta sub (take.upTo sub ctx)
          else if builtins.isAttrs sub && sub ? __functor && sub ? includes then
            sub // { includes = map (applyDeep takeFn ctx) (sub.includes or [ ]); }
          else
            sub
        ) rRaw.includes;
      }
    else
      r;

  parametric.applyIncludes =
    takeFn: aspect:
    aspect
    // {
      __functor =
        self: ctx:
        withIdentity self {
          includes = builtins.filter (x: x != { }) (map (applyDeep takeFn ctx) (self.includes or [ ]));
        };
    };

  mapIncludes =
    branch: leaf: aspect:
    aspect
    // {
      includes = map (
        include: if include ? includes && !include ? __functor then branch include else leaf include
      ) (aspect.includes or [ ]);
    };

  parametric.atLeast = parametric.applyIncludes take.atLeast;

  parametric.exactly = parametric.applyIncludes take.exactly;

  parametric.expands =
    attrs: parametric.withOwn (aspect: ctx: parametric.atLeast aspect (ctx // attrs));

  deepRecurse =
    include: branch: leaf: aspect:
    aspect
    // {
      __functor =
        self:
        { class, aspect-chain }:
        withIdentity self {
          includes = [
            (include self { inherit class aspect-chain; })
            (mapIncludes (deepRecurse include branch leaf) leaf (branch aspect))
          ];
        };
    };

  includeOwnedAndStatics = self: staticCtx: {
    includes = [
      (owned self)
      (statics self staticCtx)
    ];
  };

  includeNothing = (_: _: { });

  parametric.deep = functor: deepRecurse includeOwnedAndStatics functor lib.id;
  parametric.deepParametrics = functor: deepRecurse includeNothing lib.id functor;

  parametric.fixedTo.__functor = _: attrs: parametric.deep (lib.flip parametric.atLeast attrs);
  parametric.fixedTo.exactly = attrs: parametric.deepParametrics (lib.flip take.exactly attrs);
  parametric.fixedTo.atLeast = attrs: parametric.deepParametrics (lib.flip take.atLeast attrs);
  parametric.fixedTo.upTo = attrs: parametric.deepParametrics (lib.flip take.upTo attrs);

  parametric.withOwn =
    functor: aspect:
    aspect
    // {
      __functor =
        self: ctx:
        withIdentity self {
          includes =
            if isCtxStatic ctx then
              [
                (owned self)
                (statics self ctx)
              ]
            else
              [ (functor self ctx) ];
        };
    };

  parametric.withIdentity = withIdentity;

  parametric.__functor = _: parametric.withOwn parametric.atLeast;
in
parametric
