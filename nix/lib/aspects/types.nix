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

  providerType =
    cnf:
    let
      pft = providerFnType cnf;
      at = aspectType cnf;
      eth = lib.types.either pft at;
    in
    eth
    // {
      merge =
        loc: defs:
        let
          hasFns = builtins.any (d: lib.isFunction d.value) defs;
          hasNonFns = builtins.any (d: !lib.isFunction d.value) defs;
          isMixed = hasFns && hasNonFns;
        in
        if isMixed then
          # Mixed function + attrset defs: coerce parametric functions to
          # { includes = [fn]; } so they merge as aspects instead of being
          # evaluated as NixOS modules (which would fail on missing host/user args).
          at.merge loc (
            map (
              d:
              if lib.isFunction d.value && !isSubmoduleFn d.value then
                d
                // {
                  value = {
                    includes = [ d.value ];
                  };
                }
              else
                d
            ) defs
          )
        else
          eth.merge loc defs;
    };

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
        imports = [
          (lib.mkAliasOptionModule [ "_" ] [ "provides" ])
          (den.schema.aspect or { })
        ];

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
                description = "Legacy adapter function for resolution";
                type = lib.types.nullOr (
                  lib.types.mkOptionType {
                    name = "adapterFunction";
                    description = "function adapter";
                    check = lib.isFunction;
                    merge = _: defs: (lib.last defs).value;
                  }
                );
                default = null;
              };
              options.handleWith = lib.mkOption {
                description = "Resolution handlers for this aspect's subtree";
                type = lib.types.nullOr (
                  lib.types.mkOptionType {
                    name = "handlerValue";
                    description = "handler record or list of handler records";
                    check = v: builtins.isAttrs v || builtins.isList v;
                    merge = _: defs: (lib.last defs).value;
                  }
                );
                default = null;
              };
              options.excludes = lib.mkOption {
                description = "Aspects to exclude from this subtree (sugar for handleWith)";
                type = lib.types.listOf lib.types.unspecified;
                default = [ ];
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
  # directly delegates to the either type's merge.
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
