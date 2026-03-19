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
    See also: https://github.com/vic/den/issues/160, https://github.com/vic/flake-aspects/pull/31
  '';

  forwardEach = fwd: {
    includes = map (item: forwardOne (fwd // { each = [ item ]; })) fwd.each;
  };

  forwardOne =
    {
      guard ? null,
      adaptArgs ? null,
      adapterModule ? null,
      ...
    }@fwd:
    let
      clean = builtins.removeAttrs fwd [
        "guard"
        "adaptArgs"
        "adapterModule"
      ];
      item = lib.head fwd.each;
      fromClass = fwd.fromClass item;
      intoClass = fwd.intoClass item;
      intoPath = fwd.intoPath item;
      freeformMod = {
        config._module.freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
      };
      adapterKey = lib.concatStringsSep "/" (
        [
          fromClass
          intoClass
        ]
        ++ intoPath
      );

      guardArgs = if guard == null then { } else lib.functionArgs guard;
      guardFn =
        args: guarded:
        let
          res = (if guard == null then _: true else guard) args;
        in
        if lib.isFunction res then res item guarded else lib.optionalAttrs res guarded;

      adapter = {
        includes = [
          (den.lib.aspects.forward (
            clean
            // {
              intoPath = _: [
                "den"
                "fwd"
                adapterKey
              ];
            }
          ))
        ];
        ${intoClass} = {
          __functionArgs = guardArgs;
          __functor = _: args: {
            options.den.fwd.${adapterKey} = lib.mkOption {
              default = { };
              type = lib.types.submoduleWith {
                specialArgs = if adaptArgs == null then args else adaptArgs args;
                modules = if adapterModule == null then [ freeformMod ] else [ adapterModule ];
              };
            };
            config = guardFn args (lib.setAttrByPath intoPath args.config.den.fwd.${adapterKey});
          };
        };
      };

      needsAdapter = guard != null || adaptArgs != null || adapterModule != null;
      forwarded = den.lib.aspects.forward clean;
    in
    if needsAdapter then adapter else forwarded;

in
{
  den.provides.forward = {
    inherit description;
    __functor = _self: forwardEach;
  };
}
