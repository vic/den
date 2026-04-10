{
  lib,
  den,
  ...
}:
let
  inherit (den.lib) parametric;

  allHosts = lib.concatMap builtins.attrValues (builtins.attrValues den.hosts);
  allHomes = lib.concatMap builtins.attrValues (builtins.attrValues den.homes);
  allUsers = lib.concatMap (h: builtins.attrValues h.users) allHosts;

  deps = map (from: {
    ${from.name} = parametric (lib.genAttrs (from.classes or [ from.class ]) (_: { }));
  }) (allHosts ++ allHomes ++ allUsers);
in
{
  den.aspects = lib.mkMerge deps;
}
