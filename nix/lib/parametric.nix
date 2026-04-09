{ lib, den, ... }:
let
  inherit (den.lib) take;
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
        provider = meta.provider or [ ];
      };
    }
    // extra;

  # When takeFn succeeds and returns a result with sub-includes,
  # also try to resolve those sub-includes with takeFn. This handles
  # provider sub-aspect functions nested inside include results:
  # e.g. wrapped_fn returns { includes = [foo._.sub]; } where foo._.sub
  # needs parametric context applied before reaching the static pipeline.
  applyDeep =
    takeFn: ctx: fn:
    let
      r = takeFn fn ctx;
      # Bare provider results carry only includes (+ name from carryAttrs).
      # Results from withOwn/withIdentity have meta; deferred deepRecurse
      # wrappers have __functor. Re-resolving either would double-apply
      # context and duplicate modules.
      isBareResult = builtins.isAttrs r && r ? includes && !(r ? meta) && !(r ? __functor);
    in
    if r == { } then
      r
    else if isBareResult then
      r
      // {
        includes = map (
          sub:
          let
            sr = takeFn sub ctx;
          in
          if sr != { } then sr else sub
        ) r.includes;
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
