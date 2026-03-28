{ den, lib, ... }:
let
  description = ''
    An aspect that imports all modules defined for `from` class
    into a target `into` submodule.

    This can be used to create custom Nix classes that help
    people separating concerns on huge module hierarchies.

    For example, using a new `user` class that forwards all its
    settings into `users.users.<userName>` allows:

      den.aspects.alice.nixos.users.users.alice.isNormalUser = true;

    to become:

      den.aspects.alice.user.isNormalUser = true;


    This is exactly how `homeManager` class support is implemented in Den.
    See home-manager/hm-integration.nix.

    Den also provides the mentioned `user` class (`den._.os-user`) for setting 
    NixOS/Darwin options under `users.users.<userName>` at os-level.

    Any other user-environments like `nix-maid` or `hjem` or user-custom classes
    are easily implemented using `den._.forward`.

    Note: `den._.forward` returns an aspect that needs to be included for
    the new class to exist.

    See templates/ci/modules/guarded-forward.nix, templates/ci/modules/forward-from-custom-class.nix
    See also: https://github.com/vic/den/issues/160
  '';

  forwardEach = fwd: {
    includes = map (item: forwardItem (fwd // { inherit item; })) fwd.each;
  };

  forwardItem =
    {
      item,
      guard ? null,
      adaptArgs ? null,
      adapterModule ? null,
      asSubmodule ? true,
      ...
    }@fwd:
    let
      fromClass = fwd.fromClass item;
      intoClass = fwd.intoClass item;
      intoPath =
        let
          raw = fwd.intoPath;
        in
        if lib.functionArgs raw != { } then raw else raw item;

      intoPathArgs = if builtins.isFunction intoPath then lib.functionArgs intoPath else { };
      intoPathFn = if builtins.isFunction intoPath then intoPath else _: intoPath;
      staticIntoPath = if builtins.isFunction intoPath then [ ] else intoPath;

      asp = fwd.fromAspect item;
      sourceModule = den.lib.aspects.resolve fromClass asp;

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
        config._module.freeformType = lib.types.lazyAttrsOf lib.types.anything;
      };

      adapterMods = [ (if adapterModule == null then freeformMod else adapterModule) ];

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

      adapter = {
        includes = [
          (forward [
            "den"
            "fwd"
            adapterKey
          ])
        ];
        ${intoClass} = {
          __functionArgs = guardArgs // intoPathArgs;
          __functor = _: args: {
            options.den.fwd.${adapterKey} = lib.mkOption {
              default = { };
              type = lib.types.submoduleWith {
                specialArgs = if adaptArgs == null then args else adaptArgs args;
                modules = adapterMods;
              };
            };
            config = guardFn args (lib.setAttrByPath (intoPathFn args) args.config.den.fwd.${adapterKey});
          };
        };
      };

      extraArgsFor =
        args:
        if adaptArgs == null then { } else builtins.removeAttrs (adaptArgs args) (builtins.attrNames args);

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

in
{
  den.provides.forward = {
    inherit description;
    __functor = _self: forwardEach;
  };
}
