{ lib, den, ... }:
let
  inherit (den.lib) lastFunctionTo;

  isSubmoduleFn =
    m:
    let
      args = lib.functionArgs m;
    in
    builtins.any (k: args ? ${k}) [
      "lib"
      "config"
      "options"
      "aspect"
    ];

  providerArgNames = [
    "aspect-chain"
    "class"
  ];

  isProviderFn =
    f:
    let
      names = builtins.attrNames (lib.functionArgs f);
    in
    names != [ ] && builtins.all (n: builtins.elem n providerArgNames) names;

  directProviderFn = cnf: lib.types.addCheck (lastFunctionTo (aspectSubmodule cnf)) isProviderFn;

  curriedProviderFn =
    cnf:
    lib.types.addCheck (lastFunctionTo (providerType cnf)) (
      f:
      builtins.isFunction f
      ||
        builtins.isAttrs f
        &&
          builtins.removeAttrs f [
            "__functor"
            "__functionArgs"
          ] == { }
    );

  providerFn = cnf: lib.types.either (directProviderFn cnf) (curriedProviderFn cnf);

  providerType = cnf: lib.types.either (providerFn cnf) (aspectSubmodule cnf);

  aspectSubmodule =
    cnf:
    lib.types.submodule (
      { name, config, ... }:
      {
        freeformType = lib.types.lazyAttrsOf lib.types.deferredModule;
        config._module.args.aspect = config;
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
            description = ''
              Aspect meta data.

              Useful for attaching things that need to be communicated between
              aspects or tools inspecting aspects.

              For example, you can use it to filter out some aspects based on
              meta-data, or define icons/colors to use for graph generators.
            '';
            example = lib.literalExpression ''
              { 
                needs-unfree = [ "steam" ];
                graph.icon = "gaming";
              }
            '';
            defaultText = lib.literalExpression "{ }";
            default = { };
            type = lib.types.deferredModule;
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
            type = lib.types.submodule (
              { config, ... }:
              {
                freeformType = lib.types.lazyAttrsOf (providerType cnf);
                config._module.args.aspects = config;
              }
            );
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

  aspectsType =
    cnf:
    lib.types.submodule (
      { config, ... }:
      {
        freeformType = lib.types.lazyAttrsOf (
          lib.types.either (lib.types.addCheck (aspectSubmodule cnf) (
            m: (!builtins.isFunction m) || isSubmoduleFn m
          )) (providerType cnf)
        );
        config._module.args.aspects = config;
      }
    );

in
{
  inherit aspectsType aspectSubmodule providerType;
}
