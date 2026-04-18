{ lib, den, ... }:
ctxNs:
let
  inherit (den.lib) parametric;

  noop = _: { };

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

  resolveAspect = path: lib.attrByPath path null ctxNs;

  getCrossProvider = p: (p.prev.provides.${p.key} or (_: noop)) p.prevCtx;

  traverse =
    args@{
      prev,
      prevCtx,
      self,
      ctx,
      key,
    }:
    let
      intoList = flattenInto ((self.into or noop) ctx) [ ];
      expandOne =
        { path, into }:
        let
          aspect = resolveAspect path;
          aspectKey = lib.concatStringsSep "." path;
          pathHead = lib.head path;
          hasProvider = self.provides ? ${pathHead};
        in
        if aspect != null then
          lib.concatMap (
            c:
            traverse {
              prev = self;
              prevCtx = ctx;
              self = aspect;
              ctx = c;
              key = aspectKey;
            }
          ) into
        else if builtins.length path == 1 && hasProvider then
          lib.concatMap (
            c:
            traverse {
              prev = self;
              prevCtx = ctx;
              self = {
                name = pathHead;
                into = noop;
              };
              ctx = c;
              key = pathHead;
            }
          ) into
        else
          [ ];
    in
    [ args ] ++ lib.concatMap expandOne intoList;

  buildIncludes =
    item:
    let
      isFirst = !(item.seen ? ${item.key});
      selfProvider = item.self.provides.${item.self.name} or noop;
      crossProvider = getCrossProvider item;
      # Strip into — ctxApply already processed it. Leaving it on would cause
      # aspectToEffect to re-attach it after parametric resolution, attempting
      # to call the function without the original context args.
      stripped = builtins.removeAttrs item.self [ "into" ];
    in
    [
      (if isFirst then parametric.fixedTo item.ctx stripped else parametric.atLeast stripped item.ctx)
      (selfProvider item.ctx)
      (crossProvider item.ctx)
    ];

  assembleIncludes =
    items:
    let
      step = acc: item: {
        seen = acc.seen // {
          ${item.key} = true;
        };
        result = acc.result ++ (buildIncludes (item // { inherit (acc) seen; }));
      };
    in
    (lib.foldl' step {
      seen = { };
      result = [ ];
    } items).result;

  ctxApply =
    self: ctx:
    parametric.withIdentity self {
      includes = assembleIncludes (traverse {
        prev = null;
        prevCtx = null;
        key = self.name;
        inherit self ctx;
      });
    };

in
ctxApply
