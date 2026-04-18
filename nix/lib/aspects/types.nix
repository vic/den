{ lib, den, ... }:
let
  inherit (den.lib) lastFunctionTo canTake;

  isSubmoduleFn = canTake.upTo {
    lib = true;
    config = true;
    options = true;
  };

  # Aspects are submodules with freeform class keys (nixos, homeManager, etc.)
  # plus structural options (name, meta, includes, provides, __functor).
  #
  # Functions with named args (like { host, ... }: { nixos = ...; }) are
  # coerced to { includes = [fn]; } so the fx pipeline resolves them via
  # bind.fn effects. NixOS module functions (taking lib/config/options) are
  # NOT coerced — they're handled by wrapChild's normalizeModuleFn.

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

  providerType =
    cnf:
    let
      at = aspectType cnf;
    in
    lib.types.mkOptionType {
      name = "provider";
      description = "aspect or function returning aspect";
      check = v: builtins.isAttrs v || lib.isFunction v;
      merge =
        loc: defs:
        let
          hasFns = builtins.any (d: lib.isFunction d.value) defs;
          hasNonFns = builtins.any (d: !lib.isFunction d.value) defs;
          isMixed = hasFns && hasNonFns;
        in
        if isMixed then
          # Mixed function + attrset defs: coerce parametric functions to
          # { includes = [fn]; } so they merge as aspects.
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
        else if hasFns then
          # All functions: use lastFunctionTo merge (last def wins).
          (lastFunctionTo (providerType cnf)).merge loc defs
        else
          at.merge loc defs;
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

          __functor = lib.mkOption {
            internal = true;
            visible = false;
            description = "Functor — default is lib.const (ignores context)";
            type = lastFunctionTo (providerType cnf);
            defaultText = lib.literalExpression "lib.const";
            default = lib.const;
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

  # Coerce non-module functions to { includes = [fn]; } at the aspects level.
  # This is how { host, ... }: { nixos = ...; } becomes a proper aspect
  # with the function as a parametric include for the fx pipeline.
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
