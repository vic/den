{
  lib,
  den,
  fx,
  ...
}:
let
  aspectPath = a: (a.meta.provider or [ ]) ++ [ (a.name or "<anon>") ];

  pathKey = path: lib.concatStringsSep "/" path;

  toPathSet =
    paths:
    builtins.listToAttrs (
      builtins.map (p: {
        name = pathKey p;
        value = true;
      }) paths
    );

  tombstone = resolved: extra: {
    name = "~${resolved.name or "<anon>"}";
    meta =
      (resolved.meta or { })
      // {
        excluded = true;
        originalName = resolved.name or "<anon>";
      }
      // extra;
    includes = [ ];
  };

in
{
  inherit
    aspectPath
    pathKey
    toPathSet
    tombstone
    ;
}
