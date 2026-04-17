# Query whether an aspect is structurally present in a resolved tree.
# Entity-facing wiring lives in modules/context/has-aspect.nix.
{ lib, den, ... }:
let
  inherit (den.lib.aspects) adapters resolve;
  inherit (adapters) pathKey toPathSet;

  # Validate a ref has both `name` and `meta` (aspectPath requires
  # both) and return its slash-joined path key.
  refKey =
    ref:
    if (ref ? name) && (ref ? meta) then
      pathKey (adapters.aspectPath ref)
    else
      throw "hasAspect: ref must have both `name` and `meta` (got ${builtins.typeOf ref}).";

  # Run collectPaths under `class` on `tree`, returned as an
  # attrset-as-set keyed by slash-joined path.
  collectPathSet =
    { tree, class }: toPathSet ((resolve.withAdapter adapters.collectPaths class tree).paths or [ ]);

  hasAspectIn =
    {
      tree,
      class,
      ref,
    }:
    (collectPathSet { inherit tree class; }) ? ${refKey ref};

  # Build the functor+attrs value attached to entities as `.hasAspect`.
  # Per-class path sets are thunk-cached inside `setFor` so repeated
  # calls share one traversal per class.
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
