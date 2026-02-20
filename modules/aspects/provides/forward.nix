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

    Note: `den._.forward` is a high-level aspect, its result 
    is another aspect that needs to be included for the new class to exist.

    See templates/ci/modules/forward.nix for usage example.
    See also: https://github.com/vic/den/issues/160, https://github.com/vic/flake-aspects/pull/31
  '';

  forward =
    {
      adaptArgs ? null,
      adapterModule ? null,
      ...
    }@fwd:
    let
      forwarded = den.lib.aspects.forward clean;
      clean = builtins.removeAttrs fwd [
        "adaptArgs"
        "adapterModule"
      ];
      fromClass = fwd.fromClass (lib.head fwd.each);
      intoClass = fwd.intoClass (lib.head fwd.each);
      intoPath = fwd.intoPath (lib.head fwd.each);
      adapter =
        { class, aspect-chain }:
        {
          includes = [
            (den.lib.aspects.forward (
              clean
              // {
                intoPath = _: [
                  "den"
                  "fwd-adapter"
                  fromClass
                ];
              }
            ))
          ];
          ${intoClass} = args: {
            options.den.fwd-adapter.${fromClass} = lib.mkOption {
              default = { };
              type = lib.types.submoduleWith {
                specialArgs = adaptArgs args;
                modules =
                  if adapterModule == null then
                    [
                      {
                        config._module.freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
                      }
                    ]
                  else
                    [ adapterModule ];
              };
            };
            config = lib.setAttrByPath intoPath args.config.den.fwd-adapter.${fromClass};
          };
        };
    in
    if adaptArgs == null then forwarded else adapter;

in
{
  den.provides.forward = {
    inherit description;
    __functor = _self: forward;
  };
}
