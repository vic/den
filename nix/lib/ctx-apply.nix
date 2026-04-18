{ lib, den, ... }:
ctxNs:
let
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

  # Tag an attrset with __ctx for the pipeline's constantHandler.
  tagCtx = ctx: v: if builtins.isAttrs v && v != { } then v // { __ctx = ctx; } else v;

  buildIncludes =
    item:
    let
      selfProvider = item.self.provides.${item.self.name} or noop;
      crossProvider = getCrossProvider item;
      stripped = builtins.removeAttrs item.self [ "into" ];
    in
    map (tagCtx item.ctx) [
      stripped
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
    let
      meta = self.meta or { };
    in
    {
      name = self.name or "<anon>";
      meta = {
        handleWith = meta.handleWith or null;
        excludes = meta.excludes or [ ];
        provider = meta.provider or [ ];
      };
      includes = assembleIncludes (traverse {
        prev = null;
        prevCtx = null;
        key = self.name;
        inherit self ctx;
      });
      __ctx = ctx;
    };

in
ctxApply
