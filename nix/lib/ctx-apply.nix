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
    source: ctxPrev: self: ctxValue: key:
    [
      {
        inherit source ctxPrev key;
        ctx = ctxValue;
        ctxDef = self;
      }
    ]
    ++ lib.concatMap (
      { path, into }:
      let
        target = lib.attrByPath path null ctxNs;
        tkey = lib.concatStringsSep "." path;
        recurse = t: k: lib.concatMap (v: transformAll self ctxValue t v k) into;
      in
      if target != null then
        recurse target tkey
      else if builtins.length path == 1 && self.provides ? ${lib.head path} then
        let
          name = lib.head path;
        in
        recurse {
          inherit name;
          into = noop;
        } name
      else
        [ ]
    ) (flattenInto ((self.into or noop) ctxValue) [ ]);

  noop = _: { };

  crossProvider = p: p.source.provides.${p.key} or (_: noop);

  buildIncludes =
    items:
    let
      step =
        acc: p:
        let
          clean = cleanCtx p.ctxDef;
          isFirst = !(acc.seen ? ${p.key});
          selfFun = p.ctxDef.provides.${p.ctxDef.name} or noop;
          crossFun = crossProvider p p.ctxPrev;
        in
        {
          seen = acc.seen // {
            ${p.key} = true;
          };
          result = acc.result ++ [
            (if isFirst then parametric.fixedTo p.ctx clean else parametric.atLeast clean p.ctx)
            (selfFun p.ctx)
            (crossFun p.ctx)
          ];
        };
    in
    (lib.foldl' step {
      seen = { };
      result = [ ];
    } items).result;

  ctxApply = self: ctxValue: {
    includes = buildIncludes (transformAll null null self ctxValue self.name);
  };

in
ctxApply
