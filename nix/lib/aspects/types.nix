{ lib, den, ... }:
let
  inherit (den.lib) lastFunctionTo canTake;

  isSubmoduleFn = canTake.upTo {
    lib = true;
    config = true;
    options = true;
  };

  isProviderFn = canTake.upTo {
    aspect-chain = true;
    class = true;
  };

  isOtherCtxFn = f: builtins.isFunction f && !isSubmoduleFn f && !isProviderFn f;

  # { class, aspect-chain } => provider
  leafProviderFnType = cnf: lib.types.addCheck (lastFunctionTo (providerType cnf)) isProviderFn;

  # { anything } => provider
  curriedProviderFnType = cnf: lib.types.addCheck (lastFunctionTo (providerType cnf)) isOtherCtxFn;

  providerFnType =
    cnf:
    let
      eth = lib.types.either (leafProviderFnType cnf) (curriedProviderFnType cnf);
    in
    eth
    // {
      merge =
        loc: defs:
        (aspectType cnf).merge loc [
          {
            file = (lib.last defs).file;
            value = {
              __functor = _: eth.merge loc defs;
            };
          }
        ];
    };

  providerType = cnf: lib.types.either (providerFnType cnf) (aspectType cnf);

  aspectType =
    cnf:
    let
      sub = aspectSubmodule cnf;
    in
    sub // { merge = mergeWithAspectMeta sub; };

  mergeWithAspectMeta =
    sub: loc: defs:
    sub.merge loc (
      defs
      ++ [
        {
          file = (lib.last defs).file;
          value = aspectMeta loc defs;
        }
      ]
    );

  aspectMeta =
    loc: defs:
    { config, ... }:
    let
      names = map (x: if builtins.isString x then x else "<anon>") config.meta.loc;
      nameFromLoc = lib.concatStringsSep "." names;
    in
    {
      meta.name = lib.mkForce nameFromLoc;
      meta.file = lib.mkForce (lib.last defs).file;
      meta.loc = lib.mkForce loc;
    };

  aspectSubmodule =
    cnf:
    lib.types.submodule (
      { name, config, ... }:
      {
        freeformType = lib.types.lazyAttrsOf lib.types.deferredModule;
        imports = [ (lib.mkAliasOptionModule [ "_" ] [ "provides" ]) ];

        options = {
          name = lib.mkOption {
            description = "Aspect name";
            defaultText = lib.literalExpression "name";
            default = name;
            type = lib.types.str;
          };

          description = lib.mkOption {
            description = "Aspect description";
            defaultText = lib.literalExpression "name";
            default = "Aspect ${name}";
            type = lib.types.str;
          };

          meta = lib.mkOption {
            description = "Aspect attached meta data";
            type = lib.types.submodule {
              freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
              config.self = config;
              options.adapter = lib.mkOption {
                description = "Adapter to compose into resolution for this aspect's subtree";
                type = lib.types.nullOr (lastFunctionTo lib.types.raw);
                default = null;
              };
              options.provider = lib.mkOption {
                internal = true;
                visible = false;
                description = "Provider path tracking aspect provenance";
                type = lib.types.listOf lib.types.str;
                default = cnf.providerPrefix or [ ];
              };
            };
            defaultText = lib.literalExpression "{ }";
            default = { };
          };

          includes = lib.mkOption {
            description = "Providers to ask aspects from";
            type = lib.types.listOf (providerType cnf);
            defaultText = lib.literalExpression "[ ]";
            default = [ ];
          };

          provides = lib.mkOption {
            description = "Providers of aspect for other aspects";
            defaultText = lib.literalExpression "{ }";
            default = { };
            type = lib.types.submodule {
              freeformType = lib.types.lazyAttrsOf (
                providerType (
                  cnf
                  // {
                    providerPrefix = (cnf.providerPrefix or [ ]) ++ [ config.name ];
                  }
                )
              );
            };
          };

          __functor = lib.mkOption {
            internal = true;
            visible = false;
            description = "Functor to default provider";
            type = lastFunctionTo (providerType cnf);
            defaultText = lib.literalExpression "lib.const";
            default = cnf.defaultFunctor or lib.const;
          };
        };
      }
    );

  # Wrap non-module functions into { includes = [fn] } so they don't get
  # treated as module functions by aspectType's submodule merge.
  #
  # Only coerce functions that destructure a context attrset
  # (`{ host, ... }: ...`, `{ user, ... }: ...`, etc.) — those have a
  # non-empty `functionArgs`. Bare-arg "factory" functions like
  # `facter = reportPath: { nixos = ...; }` have empty `functionArgs`
  # and must NOT be coerced — coercing them turns `den.aspects.facter`
  # into a full aspect whose default functor ignores the user's
  # argument, so `(facter ./facter.json)` no longer materializes the
  # config. Such functions stay typed as `providerFnType`, whose merge
  # wraps the underlying function via `__functor = _: eth.merge loc
  # defs` so `(aspect arg)` correctly invokes the user function.
  coercedProviderType =
    cnf:
    let
      pt = providerType cnf;
    in
    lib.types.coercedTo (lib.types.addCheck lib.types.raw (
      v: builtins.isFunction v && !isSubmoduleFn v && lib.functionArgs v != { }
    )) (fn: { includes = [ fn ]; }) pt;

  aspectsType =
    cnf: lib.types.submodule { freeformType = lib.types.lazyAttrsOf (coercedProviderType cnf); };

in
{
  inherit aspectsType aspectType providerType;
}
