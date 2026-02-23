{ den, lib, ... }:
let
  inherit (den.lib) parametric;
  inherit (den.lib.aspects.types) providerType;

  ctxType = lib.types.submodule (
    { name, ... }:
    {
      freeformType = lib.types.lazyAttrsOf lib.types.deferredModule;
      options = {
        name = lib.mkOption {
          description = "Context type name";
          type = lib.types.str;
          default = name;
        };
        desc = lib.mkOption {
          description = "Context description";
          type = lib.types.str;
          default = "";
        };
        conf = lib.mkOption {
          description = "Obtain a configuration aspect for context";
          type = lib.types.functionTo providerType;
          default = { };
        };
        into = lib.mkOption {
          description = "Context transformations";
          type = lib.types.lazyAttrsOf (lib.types.functionTo (lib.types.listOf lib.types.raw));
          default = { };
        };
        includes = lib.mkOption {
          description = "Parametric aspects to include for this context";
          type = lib.types.listOf providerType;
          default = [ ];
        };
        __functor = lib.mkOption {
          description = "Apply context with dedup across into targets.";
          type = lib.types.functionTo (lib.types.functionTo providerType);
          readOnly = true;
          internal = true;
          visible = false;
          default = ctxApply;
        };
      };
    }
  );

  cleanCtx =
    ctx:
    builtins.removeAttrs ctx [
      "name"
      "desc"
      "conf"
      "into"
      "__functor"
    ];

  collectPairs =
    self: ctx:
    [
      {
        inherit ctx;
        ctxDef = self;
      }
    ]
    ++ lib.concatLists (
      lib.mapAttrsToList (n: into: lib.concatMap (v: collectPairs den.ctx.${n} v) (into ctx)) self.into
    );

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
            n = p.ctxDef.name;
            clean = cleanCtx p.ctxDef;
            isFirst = !(acc.seen ? ${n});
            items =
              if isFirst then
                [
                  (parametric.fixedTo p.ctx clean)
                  (p.ctxDef.conf p.ctx)
                ]
              else
                [
                  (parametric.atLeast clean p.ctx)
                  (p.ctxDef.conf p.ctx)
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

  ctxApply = self: ctx: { includes = dedupIncludes (collectPairs self ctx); };

in
{
  options.den.ctx = lib.mkOption {
    default = { };
    type = lib.types.lazyAttrsOf ctxType;
  };
}
