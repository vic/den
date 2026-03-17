{ lib, den, ... }:
ctxNs:
let
  inherit (den.lib) parametric;

  ctxKeys = [
    "name"
    "description"
    "into"
    "provides"
    "__functor"
    "__functionArgs"
    "modules"
    "resolve"
    "_module"
    "_"
  ];

  cleanCtx = self: builtins.removeAttrs self ctxKeys;

  # Flatten nested into result to [ { path = [str]; into = [ctx_value]; } ].
  flattenInto =
    attrset: prefix:
    lib.concatLists (
      lib.mapAttrsToList (
        name: v:
        let
          path = prefix ++ [ name ];
        in
        if builtins.isList v then
          [
            {
              inherit path;
              into = v;
            }
          ]
        else
          flattenInto v path
      ) attrset
    );

  transformAll =
    source: self: ctxValue: key:
    [
      {
        ctx = ctxValue;
        inherit source key;
        ctxDef = self;
      }
    ]
    ++ lib.concatLists (
      map (
        { path, into }:
        let
          target = lib.attrByPath path null ctxNs;
          tkey = lib.concatStringsSep "." path;
        in
        if target != null then
          lib.concatMap (v: transformAll self target v tkey) into
        else if builtins.length path == 1 && self.provides ? ${lib.head path} then
          let
            name = lib.head path;
          in
          lib.concatMap (
            v:
            transformAll self {
              inherit name;
              into = _: { };
            } v name
          ) into
        else
          [ ]
      ) (flattenInto (self.into ctxValue) [ ])
    );

  noop = _: { };

  crossProvider = p: if p.source == null then noop else p.source.provides.${p.key} or noop;

  dedupIncludes =
    let
      go =
        acc: remaining:
        if remaining == [ ] then
          acc.result
        else
          let
            p = builtins.head remaining;
            rest = builtins.tail remaining;
            key = p.key;
            clean = cleanCtx p.ctxDef;
            isFirst = !(acc.seen ? ${key});
            selfFun = p.ctxDef.provides.${p.ctxDef.name} or noop;
            crossFun = crossProvider p;
            items = [
              (if isFirst then parametric.fixedTo p.ctx clean else parametric.atLeast clean p.ctx)
              (selfFun p.ctx)
              (crossFun p.ctx)
            ];
          in
          go {
            seen = acc.seen // {
              ${key} = true;
            };
            result = acc.result ++ items;
          } rest;
    in
    go {
      seen = { };
      result = [ ];
    };

  ctxApply = self: ctxValue: {
    includes = dedupIncludes (transformAll null self ctxValue self.name);
  };

in
ctxApply
