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

  # Default adapter imports all classModules on a single module and recurses on includes unconditonally.
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

in
{
  inherit
    module
    filter
    map
    mapAspect
    mapIncludes
    ;
}
