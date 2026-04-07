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
            file = (lib.head defs).file;
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
          file = (lib.head defs).file;
          value = aspectMeta loc defs;
        }
      ]
    );

  aspectMeta =
    loc: defs:
    { config, ... }:
    let
      names = map (x: if builtins.isString x then x else "<anon>") loc;
      nameFromLoc = lib.concatStringsSep "." names;
    in
    {
      name = nameFromLoc;
      meta.file = (lib.last defs).file;
      meta.loc = loc;
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
              self = config;
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
              freeformType = lib.types.lazyAttrsOf (providerType cnf);
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

  aspectsType = cnf: lib.types.submodule { freeformType = lib.types.lazyAttrsOf (providerType cnf); };

in
{
  inherit aspectsType aspectType providerType;
}
