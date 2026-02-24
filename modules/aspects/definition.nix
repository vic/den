{
  lib,
  den,
  ...
}:
let
  inherit (den.lib) parametric;

  mkAspect = aspect: classes: { ${aspect} = parametric (lib.genAttrs classes (_: { })); };

  toClasses =
    from:
    if from ? classes then
      map (c: {
        aspect = from.aspect;
        class = c;
      }) from.classes
    else
      [
        {
          aspect = from.aspect;
          class = from.class;
        }
      ];

  hosts = map builtins.attrValues (builtins.attrValues den.hosts);
  homes = map builtins.attrValues (builtins.attrValues den.homes);

  groupByAspect =
    pairs:
    lib.foldl' (
      acc: { aspect, class }: acc // { ${aspect} = (acc.${aspect} or [ ]) ++ [ class ]; }
    ) { } pairs;

  deps = lib.pipe hosts [
    (lib.flatten)
    (map (h: builtins.attrValues h.users))
    (users: users ++ hosts ++ homes)
    (lib.flatten)
    (lib.concatMap toClasses)
    (lib.unique)
    (groupByAspect)
    (lib.mapAttrsToList mkAspect)
  ];
in
{
  den.aspects = lib.mkMerge deps;
}
