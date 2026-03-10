{ lib, den, ... }:
let
  inherit (den.lib) parametric;

  ctxKeys = [
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

  cleanCtx = self: builtins.removeAttrs self ctxKeys;

  transformAll =
    source: self: ctx:
    [
      {
        inherit ctx source;
        ctxDef = self;
      }
    ]
    ++ lib.concatLists (
      lib.mapAttrsToList (
        name: into:
        if den.ctx ? ${name} then
          lib.concatMap (transformAll self den.ctx.${name}) into
        else if self.provides ? ${name} then
          lib.concatMap (transformAll self {
            inherit name;
            into = _: { };
          }) into
        else
          [ ]
      ) (self.into ctx)
    );

  noop = _: { };

  crossProvider = p: if p.source == null then noop else p.source.provides.${p.ctxDef.name} or noop;

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
            name = p.ctxDef.name;
            clean = cleanCtx p.ctxDef;
            isFirst = !(acc.seen ? ${name});
            selfFun = p.ctxDef.provides.${name} or noop;
            crossFun = crossProvider p;
            items = [
              (if isFirst then parametric.fixedTo p.ctx clean else parametric.atLeast clean p.ctx)
              (selfFun p.ctx)
              (crossFun p.ctx)
            ];
          in
          go {
            seen = acc.seen // {
              ${name} = true;
            };
            result = acc.result ++ items;
          } rest;
    in
    go {
      seen = { };
      result = [ ];
    };

  ctxApply = self: ctx: {
    includes = dedupIncludes (transformAll null self ctx);
  };

in
ctxApply
