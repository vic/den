{
  lib,
  den,
  ...
}:
let
  fx = den.lib.fx;
  identity = den.lib.aspects.fx.identity;

  structuralKeys = [
    "name"
    "meta"
    "includes"
    "provides"
    "into"
    "__functor"
    "__functionArgs"
  ];

  # Emit emit-class for each non-structural attr on the aspect.
  emitClasses =
    aspect: classKeys: nodeIdentity:
    fx.seq (
      map (
        k:
        fx.send "emit-class" {
          class = k;
          identity = nodeIdentity;
          module = aspect.${k};
        }
      ) classKeys
    );

  # Register constraints from meta.handleWith and meta.excludes.
  registerConstraints =
    aspect:
    let
      rawHandleWith = aspect.meta.handleWith or null;
      rawExcludes = aspect.meta.excludes or [ ];
      handleWithList =
        if rawHandleWith == null then
          [ ]
        else if builtins.isList rawHandleWith then
          rawHandleWith
        else if builtins.isAttrs rawHandleWith then
          [ rawHandleWith ]
        else
          [ ];
      excludeList = map (ref: {
        type = "exclude";
        scope = "subtree";
        identity = identity.pathKey (identity.aspectPath ref);
      }) rawExcludes;
      allConstraints = handleWithList ++ excludeList;
      owner = aspect.name or "<anon>";
    in
    fx.seq (map (c: fx.send "register-constraint" (c // { inherit owner; })) allConstraints);

  # Fold includes through emit-include effects.
  emitIncludes =
    incs:
    builtins.foldl' (
      acc: child:
      fx.bind acc (
        results: fx.bind (fx.send "emit-include" child) (childResults: fx.pure (results ++ childResults))
      )
    ) (fx.pure [ ]) incs;

  # Emit into-transition effects for each key in aspect.into.
  # into is a function ctx → attrset. We pass the unevaluated function
  # to the handler which evaluates it with the current context.
  emitTransitions =
    aspect:
    if aspect ? into then
      fx.send "into-transition" {
        intoFn = aspect.into;
        self = aspect;
      }
    else
      fx.pure [ ];

  # Self-provide: if aspect.provides.${aspect.name} exists, emit it as an include.
  emitSelfProvide =
    aspect:
    let
      name = aspect.name or "<anon>";
      provides = aspect.provides or { };
    in
    if provides ? ${name} then
      fx.send "emit-include" {
        inherit name;
        meta = {
          provider = (aspect.meta.provider or [ ]) ++ [ name ];
          selfProvide = true;
        };
        __functor = _: ctx: provides.${name} ctx;
        __functionArgs = { };
        includes = [ ];
      }
    else
      fx.pure [ ];

  # Wrap a computation in chain-push/chain-pop if the node is meaningful.
  chainWrap =
    nodeIdentity: isMeaningful: comp:
    if isMeaningful then
      fx.bind (fx.send "chain-push" { identity = nodeIdentity; }) (
        _: fx.bind comp (result: fx.bind (fx.send "chain-pop" null) (_: fx.pure result))
      )
    else
      comp;

  # Resolve children, assemble the result, and emit resolve-complete.
  resolveChildren =
    aspect:
    { isMeaningful, nodeIdentity }:
    fx.bind
      (chainWrap nodeIdentity isMeaningful (
        fx.bind (emitSelfProvide aspect) (
          selfProvResults:
          fx.bind (emitTransitions aspect) (
            transitionResults:
            fx.bind (emitIncludes (aspect.includes or [ ])) (
              children: fx.pure (selfProvResults ++ transitionResults ++ children)
            )
          )
        )
      ))
      (
        allChildren:
        let
          resolved = aspect // {
            includes = allChildren;
          };
        in
        fx.bind (fx.send "resolve-complete" resolved) (_: fx.pure resolved)
      );

  # Compile a static (non-functor) aspect into an effectful computation.
  compileStatic =
    aspect:
    let
      nodeIdentity = identity.pathKey (identity.aspectPath aspect);
      classKeys = builtins.filter (k: !(builtins.elem k structuralKeys)) (builtins.attrNames aspect);
      rawName = aspect.name or "<anon>";
      isMeaningful =
        rawName != "<anon>" && rawName != "<function body>" && !(lib.hasPrefix "[definition " rawName);
    in
    fx.bind (fx.seq [
      (emitClasses aspect classKeys nodeIdentity)
      (registerConstraints aspect)
    ]) (_: resolveChildren aspect { inherit isMeaningful nodeIdentity; });

  # The aspect compiler.
  #
  # In the fx pipeline, __functor on aspects is NEVER the user's function.
  # The type system always sets it to defaultFunctor (parametric.withOwn).
  # User-defined parametric functions live in `includes` as bare children,
  # wrapped by wrapChild with __functionArgs carrying the real arg names.
  #
  # Two cases:
  # 1. __functionArgs has named args → parametric child (from wrapChild).
  #    Resolve args via bind.fn, compile the result.
  # 2. Otherwise → static. Strip __functor/__functionArgs (legacy default),
  #    compile the attrset directly.
  #
  # Factory aspects (ctx: { ... } with bare arg) are not supported in the
  # fx pipeline. Use destructured args: { host, ... }: { ... }.
  aspectToEffect =
    aspect:
    let
      userArgs = aspect.__functionArgs or { };
      isParametric = userArgs != { } && aspect ? __functor;
    in
    if isParametric then
      let
        fn = aspect.__functor aspect;
      in
      fx.bind (fx.bind.fn { } fn) (
        resolved:
        aspectToEffect (
          {
            inherit (aspect) name;
            meta = (aspect.meta or { }) // (resolved.meta or { });
          }
          // lib.optionalAttrs (aspect ? into) { inherit (aspect) into; }
          // lib.optionalAttrs (aspect ? provides) { inherit (aspect) provides; }
          // builtins.removeAttrs (resolved) [ "meta" ]
        )
      )
    else
      compileStatic (
        builtins.removeAttrs aspect [
          "__functor"
          "__functionArgs"
        ]
      );

in
{
  inherit
    aspectToEffect
    emitIncludes
    emitTransitions
    emitSelfProvide
    ;
}
