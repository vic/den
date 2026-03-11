name: sources:
{ config, lib, ... }:
let
  from = lib.flatten [ sources ];
  isOutput = builtins.any (x: x == true) from;
  denfuls = map (lib.getAttrFromPath [
    "denful"
    name
  ]) (builtins.filter builtins.isAttrs from);

  internals = [
    "_"
    "modules"
    "resolve"
    "__functor"
  ];

  stripAspect =
    v:
    if !builtins.isAttrs v then
      v
    else
      (builtins.removeAttrs v internals)
      // lib.optionalAttrs (v ? provides) { provides = lib.mapAttrs (_: stripAspect) v.provides; };

  stripNamespace = lib.mapAttrs (_: stripAspect);

  functorModules =
    aspectPath: v:
    lib.optionals (builtins.isAttrs v) (
      lib.optional (v ? __functor) {
        config = lib.setAttrByPath aspectPath { __functor = v.__functor; };
      }
      ++ lib.concatMap (
        pname:
        functorModules (
          aspectPath
          ++ [
            "provides"
            pname
          ]
        ) v.provides.${pname}
      ) (lib.attrNames (v.provides or { }))
    );

  namespaceFunctorModules =
    ns: lib.concatMap (aname: functorModules [ "den" "ful" name aname ] ns.${aname}) (lib.attrNames ns);

  sourceModule = {
    config.den.ful.${name} = lib.mkMerge (map stripNamespace denfuls);
  };

  aliasModule = lib.mkAliasOptionModule [ name ] [ "den" "ful" name ];

  outputModule =
    if isOutput then
      {
        config.flake.denful.${name} = config.den.ful.${name};
      }
    else
      { };
in
{
  imports = [
    sourceModule
    aliasModule
    outputModule
  ]
  ++ lib.concatMap namespaceFunctorModules denfuls;
  config._module.args.${name} = config.den.ful.${name};
}
