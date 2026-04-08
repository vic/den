{ lib, ... }:
path: attrs:
assert lib.isList path;
assert lib.isAttrs attrs;
let
  # --- BRACE EXPANSION HELPERS ---
  crossProduct = prefixes: suffixes: lib.concatMap (p: map (s: p + s) suffixes) prefixes;

  tokenize =
    str:
    let
      rawTokens = lib.flatten (builtins.split "([{},])" str);
    in
    builtins.filter (x: x != "") rawTokens;

  parseSeq =
    tokens: currentVals:
    if tokens == [ ] then
      {
        vals = currentVals;
        rest = [ ];
      }
    else
      let
        head = builtins.head tokens;
        tail = builtins.tail tokens;
      in
      if head == "," || head == "}" then
        {
          vals = currentVals;
          rest = tokens;
        }
      else if head == "{" then
        let
          choiceRes = parseChoice tail;
        in
        parseSeq choiceRes.rest (crossProduct currentVals choiceRes.vals)
      else
        parseSeq tail (crossProduct currentVals [ head ]);

  parseChoice =
    tokens:
    let
      seqRes = parseSeq tokens [ "" ];
      headRest = builtins.head seqRes.rest;
      tailRest = builtins.tail seqRes.rest;
    in
    if seqRes.rest == [ ] then
      builtins.throw "Syntax error: unclosed brace"
    else if headRest == "}" then
      {
        vals = seqRes.vals;
        rest = tailRest;
      }
    else if headRest == "," then
      let
        nextChoice = parseChoice tailRest;
      in
      {
        vals = seqRes.vals ++ nextChoice.vals;
        rest = nextChoice.rest;
      }
    else
      builtins.throw "Unexpected token: ${headRest}";

  expandGlob = str: (parseSeq (tokenize str) [ "" ]).vals;

  # --- TREE WALKING & REGEX MATCHING ---

  walk =
    attrs: pathList:
    if pathList == [ ] then
      [ attrs ]
    else if builtins.isFunction attrs then
      [ attrs ]
    else if !(builtins.isAttrs attrs) then
      [ ]
    else
      let
        head = builtins.head pathList;
        tail = builtins.tail pathList;

        expandedPatterns = expandGlob head;

        patToRegex =
          pat:
          let
            escaped = lib.strings.escapeRegex pat;
          in
          builtins.replaceStrings [ "\\*" ] [ ".*" ] escaped;

        keys = builtins.attrNames attrs;
        matchedKeys = builtins.filter (
          k: lib.any (pat: builtins.match (patToRegex pat) k != null) expandedPatterns
        ) keys;
      in
      lib.concatMap (k: walk attrs.${k} tail) matchedKeys;

  # --- SMART MERGE LOGIC ---

  # Deeply merges attribute sets, but intelligently wraps functions
  smartMerge =
    a: b:
    if builtins.isFunction a || builtins.isFunction b then
      # Return a new function that resolves and merges the underlying data
      args:
      smartMerge (if builtins.isFunction a then a args else a) (
        if builtins.isFunction b then b args else b
      )
    else if builtins.isAttrs a && builtins.isAttrs b then
      # Both are sets: deeply merge their keys
      let
        allKeys = lib.unique (builtins.attrNames a ++ builtins.attrNames b);
      in
      builtins.listToAttrs (
        map (k: {
          name = k;
          value =
            if builtins.hasAttr k a && builtins.hasAttr k b then
              smartMerge a.${k} b.${k}
            else if builtins.hasAttr k b then
              b.${k}
            else
              a.${k};
        }) allKeys
      )
    else
      # Primitive conflict (e.g., string vs int). Right side wins.
      b;

  # Replaced lib.recursiveUpdate with our custom smartMerge
  extractAndMergePaths = attrs: pathList: builtins.foldl' smartMerge { } (walk attrs pathList);

in
extractAndMergePaths attrs path
