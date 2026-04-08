{ den, lib, ... }:
let
  forwardItem =
    {
      item,
      guard ? null,
      adaptArgs ? null,
      adapterModule ? null,
      ...
    }@fwd:
    let
      fromClass = fwd.fromClass item;
      intoClass = fwd.intoClass item;
      intoPath = fwd.intoPath item;
      mapModule = (fwd.mapModule or (_: lib.id)) item;

      intoPathArgs = if lib.isFunction intoPath then lib.functionArgs intoPath else { };
      intoPathFn = if lib.isFunction intoPath then intoPath else _: intoPath;
      staticIntoPath = if lib.isFunction intoPath then [ ] else intoPath;

      # Entities have .resolved (their context pipeline result); raw aspects don't.
      asp = if fwd ? fromAspect then fwd.fromAspect item else item.resolved or item;
      sourceModule = mapModule (den.lib.aspects.resolve fromClass asp);

      forward =
        path:
        let
          value = lib.setAttrByPath path (_: {
            imports = [ sourceModule ];
          });
        in
        {
          ${intoClass} = value;
        };

      freeformMod = {
        config._module.freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
      };

      adapterMods = [
        freeformMod
        (
          if lib.isFunction adapterModule then
            adapterModule item
          else if builtins.isAttrs adapterModule then
            adapterModule
          else
            { }
        )
      ];

      adapterKey = lib.concatStringsSep "/" (
        [
          fromClass
          intoClass
        ]
        ++ staticIntoPath
      );

      guardArgs = if guard == null then { } else lib.functionArgs guard;
      guardFn =
        if guard == null then
          _: lib.id
        else
          args:
          let
            res = guard args;
          in
          if lib.isFunction res then res item else lib.optionalAttrs res;

      adaptArgsFn =
        args:
        if adaptArgs == null then
          args
        else
          let
            res = adaptArgs args;
          in
          if lib.isFunction res then res item else res;
      adaptArgv = if adaptArgs == null then { } else lib.functionArgs adaptArgs;

      adapter = {
        includes = [
          (forward [
            "den"
            "fwd"
            adapterKey
          ])
        ];
        ${intoClass} = {
          __functionArgs = guardArgs // intoPathArgs // adaptArgv;
          __functor = _: args: {
            options.den.fwd.${adapterKey} = lib.mkOption {
              defaultText = lib.literalExpression "{ }";
              default = { };
              type = lib.types.submoduleWith {
                specialArgs = adaptArgsFn args;
                modules = adapterMods;
              };
            };
            config = guardFn args (lib.setAttrByPath (intoPathFn args) args.config.den.fwd.${adapterKey});
          };
        };
      };

      extraArgsFor = args: builtins.removeAttrs (adaptArgsFn args) (builtins.attrNames args);

      guardTree =
        guard: outerArgs: node:
        if builtins.isAttrs node && node ? imports then
          { imports = map (guardTree guard outerArgs) node.imports; }
        else
          _modArgs: {
            config = guard (if lib.isFunction node then node outerArgs else node);
          };

      evalImport =
        args:
        let
          extraArgs = extraArgsFor args;
          specialArgs =
            builtins.removeAttrs args [
              "config"
              "options"
              "lib"
            ]
            // extraArgs;
          evaluated = lib.evalModules {
            inherit specialArgs;
            modules = adapterMods ++ [
              sourceModule
            ];
          };
        in
        guardFn args evaluated.config;

      canDirectImport = adapterModule == null;

      topLevelAdapter.${intoClass} = {
        __functionArgs = guardArgs;
        __functor =
          _: args:
          let
            fullArgs = args // extraArgsFor args;
          in
          if canDirectImport then
            { imports = [ (guardTree (guardFn args) fullArgs sourceModule) ]; }
          else
            evalImport args;
      };

      needsAdapter =
        guard != null || adaptArgs != null || adapterModule != null || builtins.isFunction intoPath;
      needsTopLevelAdapter = needsAdapter && intoPath == [ ];
      forwarded = forward intoPath;
    in
    if needsTopLevelAdapter then
      topLevelAdapter
    else if needsAdapter then
      adapter
    else
      forwarded;

  forwardEach = fwd: {
    includes = map (item: forwardItem (fwd // { inherit item; })) fwd.each;
  };

in
{
  forwardEach = forwardEach;
}
