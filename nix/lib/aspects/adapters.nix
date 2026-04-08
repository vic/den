# Adapters for resolve.withAdapter. Default one is module.
#
# These adapters determine the return value of resolve. The adapters
# are called by resolve for each resolved aspect, and the adapter can choose
# to recurse or to replace which aspects will be used.
#
# Only basic adapters are provided here, see the arguments given by resolve.nix to them.
# Some adapters compose by taking other adapters as parameters.
{ lib, ... }:
let

  # Default adapter used by `resolve`.
  default = filterIncludes module;

  # Produces a single module importing all classModules from aspect and its includes.
  module =
    {
      classModule,
      recurse,
      aspect,
      ...
    }:
    {
      imports = classModule ++ (lib.concatMap (i: (recurse i).imports or [ ]) (aspect.includes or [ ]));
    };

  filter =
    pred: adapter: args:
    if pred args.aspect then adapter args else { };

  # transforms the result of other adapters using f.
  map =
    f: adapter: args:
    f (adapter args);

  # transform each aspect into another by applying f to it.
  mapAspect =
    f: adapter: args:
    adapter (args // { aspect = f args.aspect; });

  # transforms aspect includes by applying f to it.
  mapIncludes =
    f: adapter: args:
    adapter (args // { recurse = included: args.recurse (f included); });

  # Handles per-aspect adapter accumulation via meta.adapter.
  # Composes meta.adapter with the inner adapter, removes includes that
  # would resolve to { }, and tags survivors for downstream propagation.
  filterIncludes =
    inner:
    args@{ aspect, resolveChild, ... }:
    let
      metaAdapter = aspect.meta.adapter or null;
    in
    if metaAdapter != null && aspect ? includes then
      let
        composed = metaAdapter (filterIncludes inner);
        keeps =
          i:
          composed (
            args
            // {
              aspect = resolveChild i;
              classModule = [ ];
            }
          ) != { };
        tag =
          i:
          if builtins.isAttrs i && i.meta.adapter or null == null then
            i
            // {
              meta = (i.meta or { }) // {
                adapter = metaAdapter;
              };
            }
          else
            i;
      in
      inner (
        args
        // {
          aspect = aspect // {
            includes = builtins.map tag (lib.filter keeps aspect.includes);
          };
        }
      )
    else
      inner args;

in
{
  inherit
    default
    filter
    filterIncludes
    map
    mapAspect
    mapIncludes
    module
    ;
}
