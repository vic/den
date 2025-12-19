name: sources:
{ config, lib, ... }:
let
  from = lib.flatten [ sources ];
  isOutput = builtins.any (x: x == true) from;
  attrs = builtins.filter builtins.isAttrs from;

  # Strip module system metadata to get clean raw values
  stripMeta =
    value:
    if builtins.isFunction value then
      # drop functions - they represent parametric/aspect functors that
      # cause re-evaluation and duplication when merged as raw values
      { }
    else if builtins.isList value then
      let
        cleanedList = map stripMeta value;
      in
      builtins.filter (x: x != { }) cleanedList
    else if builtins.isAttrs value then
      let
        # Remove module system special attributes that should not be merged
        cleaned = builtins.removeAttrs value [
          "__functor"
          "__functionArgs"
          "_module"
          "config"
          "modules"
          "includes"
          "resolve"
          "provides"
          "name"
          "description"
        ];
      in
      lib.mapAttrs (_k: v: stripMeta v) cleaned
    else
      value;

  # Deep merge that concatenates lists instead of overwriting them
  deepMergeWith =
    lhs: rhs:
    if builtins.isList lhs && builtins.isList rhs then
      let
        appendUnique = l: r: l ++ builtins.filter (x: !(builtins.any (y: y == x) l)) r;
      in
      appendUnique lhs rhs
    else if builtins.isAttrs lhs && builtins.isAttrs rhs then
      let
        allKeys = lib.unique (builtins.attrNames lhs ++ builtins.attrNames rhs);
        mergedAttrs = builtins.listToAttrs (
          map (k: {
            name = k;
            value =
              if lhs ? k && rhs ? k then
                deepMergeWith lhs.${k} rhs.${k}
              else if lhs ? k then
                lhs.${k}
              else
                rhs.${k};
          }) allKeys
        );
      in
      mergedAttrs
    else
      rhs;

  # Extract denful values, strip metadata, and merge them deeply before passing to module system
  tracedSources = map (
    srcItem:
    let
      src = lib.getAttrFromPath [ "denful" name ] srcItem;
    in
    stripMeta src
  ) attrs;

  deepMerge = builtins.foldl' (acc: x: deepMergeWith acc x) { } tracedSources;

  # Normalize lists in the merged result to remove duplicates while preserving order
  normalize =
    v:
    if builtins.isList v then
      let
        dedup =
          list:
          let
            helper =
              acc: rem:
              if rem == [ ] then
                acc
              else
                let
                  h = builtins.head rem;
                  t = builtins.tail rem;
                in
                if builtins.any (x: x == h) acc then helper acc t else helper (acc ++ [ h ]) t;
          in
          helper [ ] list;
      in
      dedup v
    else if builtins.isAttrs v then
      lib.mapAttrs (_n: x: normalize x) v
    else
      v;

  normalized = normalize deepMerge;

  sourceModule = {
    # pass normalized (deduped) structure to the module system
    config.den.ful.${name} = normalized;
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
