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

  # Tag an include with its context stage for tracing.
  tagStage =
    stage: kind: aspectName: val:
    if builtins.isAttrs val then
      val
      // {
        __ctxStage = stage;
        __ctxKind = kind;
        __ctxAspect = aspectName;
      }
    else
      val;

  buildIncludes =
    item:
    let
      isFirst = !(item.seen ? ${item.key});
      selfProvider = item.self.provides.${item.self.name} or noop;
      crossProvider = getCrossProvider item;
      stage = item.key;
    in
    let
      aspect =
        if isFirst then parametric.fixedTo item.ctx item.self else parametric.atLeast item.self item.ctx;
      selfProv = selfProvider item.ctx;
      crossProv = crossProvider item.ctx;
    in
    [
      (tagStage stage "aspect" (item.self.name or "<anon>") aspect)
      (tagStage stage "self-provide" (item.self.name or "<anon>") selfProv)
      (tagStage stage "cross-provide" (
        if item.prev != null then item.prev.name or "<anon>" else "<anon>"
      ) crossProv)
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

  # Serializable summary of traversal items for tracing.
  traceItem =
    item:
    let
      ctx = if builtins.isAttrs item.ctx then item.ctx else { };
      ctxKeys = builtins.attrNames ctx;
      entityNames = lib.concatMap (
        k:
        let
          v = ctx.${k} or null;
        in
        lib.optional (builtins.isAttrs v && v ? name) {
          kind = k;
          name = v.name;
          aspect = v.aspect or v.name;
        }
      ) ctxKeys;
    in
    {
      key = item.key;
      selfName = item.self.name or "<anon>";
      prevName = if item.prev == null then null else item.prev.name or "<anon>";
      hasSelfProvider = (item.self.provides or { }) ? ${item.self.name or ""};
      hasCrossProvider = item.prev != null && (item.prev.provides or { }) ? ${item.key};
      inherit ctxKeys entityNames;
      provideNames = builtins.attrNames (item.self.provides or { });
    };

  ctxApply =
    self: ctx:
    let
      items = traverse {
        prev = null;
        prevCtx = null;
        key = self.name;
        inherit self ctx;
      };
    in
    parametric.withIdentity self {
      includes = assembleIncludes items;
      __ctxTrace = builtins.map traceItem items;
    };

in
ctxApply
