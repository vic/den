{ den, lib, ... }:
let
  inherit (den.lib) parametric;
  inherit (den.lib.aspects.types) aspectSubmodule providerType;

  ctxType = lib.types.submodule (
    { name, config, ... }:
    {
      imports = aspectSubmodule.getSubModules;
      options.into = lib.mkOption {
        description = "Context transformations to other context types";
        type = lib.types.lazyAttrsOf (
          lib.types.functionTo (lib.types.listOf lib.types.raw)
        );
        default = { };
      };
      config.__functor = lib.mkForce (ctxApply config.name);
    }
  );

  cleanCtx =
    self:
    builtins.removeAttrs self [
      "name"
      "description"
      "into"
      "provides"
      "__functor"
      "modules"
      "resolve"
      "_module"
      "_"
    ];

  collectPairs =
    source: self: ctx:
    [
      {
        inherit ctx source;
        ctxDef = self;
      }
    ]
    ++ lib.concatLists (
      lib.mapAttrsToList (
        n: into: lib.concatMap (v: collectPairs self den.ctx.${n} v) (into ctx)
      ) self.into
    );

  dedupIncludes =
    let
      crossProvider =
        p:
        let
          src = p.source;
          n = p.ctxDef.name;
        in
        if src == null then
          (_: { })
        else
          src.provides.${n} or (_: { });

      go =
        acc: remaining:
        if remaining == [ ] then
          acc.result
        else
          let
            p = builtins.head remaining;
            rest = builtins.tail remaining;
            n = p.ctxDef.name;
            clean = cleanCtx p.ctxDef;
            isFirst = !(acc.seen ? ${n});
            selfProvider = p.ctxDef.provides.${n} or (_: { });
            cross = crossProvider p;
            items =
              if isFirst then
                [
                  (parametric.fixedTo p.ctx clean)
                  (selfProvider p.ctx)
                  (cross p.ctx)
                ]
              else
                [
                  (parametric.atLeast clean p.ctx)
                  (selfProvider p.ctx)
                  (cross p.ctx)
                ];
          in
          go {
            seen = acc.seen // {
              ${n} = true;
            };
            result = acc.result ++ items;
          } rest;
    in
    pairs:
    go {
      seen = { };
      result = [ ];
    } pairs;

  ctxApply =
    ctxName: _self: ctx:
    { includes = dedupIncludes (collectPairs null den.ctx.${ctxName} ctx); };

in
{
  options.den.ctx = lib.mkOption {
    default = { };
    type = lib.types.lazyAttrsOf ctxType;
  };
}
