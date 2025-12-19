name: sources:
{ config, lib, ... }:
let
  from = lib.flatten [ sources ];
  isOutput = builtins.any (x: x == true) from;
  attrs = builtins.filter builtins.isAttrs from;
  
  # Strip module system metadata to get clean raw values
  stripMeta = value:
    if builtins.isList value then
      map stripMeta value
    else if builtins.isAttrs value then
      let
        # Remove module system special attributes
        cleaned = builtins.removeAttrs value [
          "__functor"
          "__functionArgs"
          "_module"
          "config"
        ];
      in
      lib.mapAttrs (_: stripMeta) cleaned
    else
      value;
  
  # Deep merge that concatenates lists instead of overwriting them
  deepMergeWith = lhs: rhs:
    if builtins.isList lhs && builtins.isList rhs then
      lhs ++ rhs
    else if builtins.isAttrs lhs && builtins.isAttrs rhs then
      let
        allKeys = lib.unique (builtins.attrNames lhs ++ builtins.attrNames rhs);
        mergedAttrs = builtins.listToAttrs (map (name: {
          inherit name;
          value =
            if lhs ? ${name} && rhs ? ${name} then
              deepMergeWith lhs.${name} rhs.${name}
            else if lhs ? ${name} then
              lhs.${name}
            else
              rhs.${name};
        }) allKeys);
      in
      mergedAttrs
    else
      rhs;
  
  # Extract denful values, strip metadata, and merge them deeply before passing to module system
  deepMerge = builtins.foldl' (acc: x:
    deepMergeWith acc (stripMeta (lib.getAttrFromPath [ "denful" name ] x))
  ) { } attrs;

  sourceModule = {
    config.den.ful.${name} = deepMerge;
  };

  aliasModule = lib.mkAliasOptionModule [ name ] [ "den" "ful" name ];

  outputModule =
    if isOutput then
      {
        # Use mkOptionDefault to ensure this assignment has lower priority
        # This prevents re-evaluation and duplication issues
        config.flake.denful.${name} = lib.mkOptionDefault config.den.ful.${name};
      }
    else
      { };
in
{
  imports = [
    sourceModule
    aliasModule
    outputModule
  ];
  config._module.args.${name} = config.den.ful.${name};
}
