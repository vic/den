# Query whether an aspect is structurally present in a resolved tree.
# Entity-facing wiring lives in modules/context/has-aspect.nix.
{ lib, den, ... }:
let
  inherit (den.lib.aspects.fx) identity;
  inherit (identity) aspectPath pathKey;

  refKey =
    ref:
    if (ref ? name) && (ref ? meta) then
      pathKey (aspectPath ref)
    else
      throw "hasAspect: ref must have both `name` and `meta` (got ${builtins.typeOf ref}).";

  # Resolve tree via fx pipeline and extract pathSet from state.
  # Inlines the same root normalization as fxResolveTree (default.nix)
  # to handle raw lambdas and functor attrsets.
  collectPathSet =
    { tree, class }:
    let
      isRawFn = builtins.isFunction tree;
      isFunctor = builtins.isAttrs tree && tree ? __functor;
      functorArgs = if isFunctor then builtins.functionArgs (tree.__functor tree) else { };
      needsWrap = isRawFn || (isFunctor && functorArgs != { });
      normalized =
        if needsWrap then
          let
            innerFn = if isFunctor then tree.__functor tree else tree;
            innerArgs = if isFunctor then functorArgs else builtins.functionArgs innerFn;
          in
          {
            __functor = _: innerFn;
            __functionArgs = innerArgs;
            name = tree.name or "<function body>";
            meta = tree.meta or { };
            includes = tree.includes or [ ];
          }
        else
          tree;
      ctx = tree.__ctx or { };
      result = den.lib.aspects.fx.pipeline.fxFullResolve {
        inherit class ctx;
        self = normalized;
      };
    in
    result.state.pathSet or { };

  hasAspectIn =
    {
      tree,
      class,
      ref,
    }:
    (collectPathSet { inherit tree class; }) ? ${refKey ref};

  mkEntityHasAspect =
    {
      tree,
      primaryClass,
      classes,
    }:
    let
      setFor = builtins.listToAttrs (
        map (c: {
          name = c;
          value = collectPathSet {
            inherit tree;
            class = c;
          };
        }) (lib.unique ([ primaryClass ] ++ classes))
      );
      check = class: ref: (setFor.${class} or { }) ? ${refKey ref};
      bareFn = check primaryClass;
    in
    {
      __functor = _: bareFn;
      forClass = check;
      forAnyClass = ref: lib.any (c: check c ref) classes;
    };

in
{
  inherit
    hasAspectIn
    collectPathSet
    mkEntityHasAspect
    ;
}
