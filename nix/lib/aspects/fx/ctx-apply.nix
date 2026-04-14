{
  lib,
  den,
  fx,
  adapters,
  ...
}:
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

  ctxApplyEffectful =
    ctxNs: self: ctx:
    let
      resolveAspect = path: lib.attrByPath path null ctxNs;

      traverse =
        {
          prev,
          prevCtx,
          self,
          ctx,
          key,
        }:
        fx.bind
          (fx.send "ctx-traverse" {
            inherit
              prev
              prevCtx
              self
              ctx
              key
              ;
          })
          (
            _:
            fx.bind
              (buildStageIncludes {
                inherit
                  prev
                  prevCtx
                  self
                  ctx
                  key
                  ;
              })
              (
                stageIncludes:
                let
                  intoList = flattenInto ((self.into or noop) ctx) [ ];
                in
                fx.bind (foldInto intoList { inherit self ctx; }) (
                  childIncludes: fx.pure (stageIncludes ++ childIncludes)
                )
              )
          );

      foldInto =
        intoList:
        { self, ctx }:
        builtins.foldl' (
          acc:
          { path, into }:
          fx.bind acc (
            results:
            let
              aspect = resolveAspect path;
              aspectKey = lib.concatStringsSep "." path;
              pathHead = lib.head path;
              hasProvider = self.provides ? ${pathHead};
            in
            if aspect != null then
              foldContexts into results {
                prev = self;
                prevCtx = ctx;
                self = aspect;
                key = aspectKey;
              }
            else if builtins.length path == 1 && hasProvider then
              foldContexts into results {
                prev = self;
                prevCtx = ctx;
                self = {
                  name = pathHead;
                  into = noop;
                  provides = { };
                };
                key = pathHead;
              }
            else
              fx.pure results
          )
        ) (fx.pure [ ]) intoList;

      foldContexts =
        contexts: results:
        {
          prev,
          prevCtx,
          self,
          key,
        }:
        builtins.foldl' (
          acc: c:
          fx.bind acc (
            innerResults:
            fx.bind (traverse {
              inherit
                prev
                prevCtx
                self
                key
                ;
              ctx = c;
            }) (stageResults: fx.pure (innerResults ++ stageResults))
          )
        ) (fx.pure results) contexts;

      buildStageIncludes =
        {
          prev,
          prevCtx,
          self,
          ctx,
          key,
        }:
        fx.bind (fx.send "ctx-seen" key) (
          { isFirst }:
          fx.bind
            (fx.send "ctx-provider" {
              kind = "self";
              inherit
                self
                ctx
                key
                prev
                prevCtx
                ;
            })
            (
              selfProv:
              fx.bind
                (fx.send "ctx-provider" {
                  kind = "cross";
                  inherit
                    self
                    ctx
                    key
                    prev
                    prevCtx
                    ;
                })
                (
                  crossProv:
                  let
                    aspectName = self.name or "<anon>";
                    rawMain = if isFirst then parametric.fixedTo ctx self else parametric.atLeast self ctx;
                    selfProvRaw = if selfProv != null then selfProv ctx else null;
                    crossProvRaw = if crossProv != null then crossProv ctx else null;
                    tagResult =
                      kind: tagAspect: r:
                      if builtins.isAttrs r then
                        r
                        // {
                          __ctxStage = key;
                          __ctxKind = kind;
                          __ctxAspect = tagAspect;
                        }
                      else
                        r;
                    mainAspect = tagResult "aspect" aspectName rawMain;
                    selfProvResult =
                      if selfProvRaw != null then tagResult "self-provide" aspectName selfProvRaw else null;
                    crossProvResult =
                      if crossProvRaw != null then
                        tagResult "cross-provide" (if prev != null then prev.name or "<anon>" else "<anon>") crossProvRaw
                      else
                        null;
                  in
                  fx.pure (
                    [ mainAspect ]
                    ++ lib.optional (selfProvResult != null) selfProvResult
                    ++ lib.optional (crossProvResult != null) crossProvResult
                  )
                )
            )
        );
    in
    traverse {
      prev = null;
      prevCtx = null;
      key = self.name;
      inherit self ctx;
    };

in
{
  inherit ctxApplyEffectful flattenInto;
}
