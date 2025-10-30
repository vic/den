{
  inputs,
  lib,
  den,
  ...
}:
let
  home-manager.description = ''
    integrates home-manager into nixos/darwin OS classes.

    usage:

      for using home-manager in just a particular host:

        den.aspects.my-laptop._.host.includes = [ den.home-manager ];

      for enabling home-manager by default on all hosts:

        den.default.host.includes = [ den.home-manager ];

    Does nothing for hosts that have no users with `homeManager` class.
    Expects `inputs.home-manager` to exist. If `<host>.hm-module` exists
    it is the home-manager.{nixos/darwin}Modules.home-manager.

    For each user resolves den.aspects.''${user.aspect} and imports its homeManager class module.
  '';

  home-manager.__functor =
    _:
    { host }:
    { class, aspect-chain }:
    let
      hmUsers = builtins.filter (u: u.class == "homeManager") (lib.attrValues host.users);

      hmUserModule =
        user:
        let
          ctx = {
            inherit aspect-chain;
            class = "homeManager";
          };
          aspect = den.aspects.${user.aspect}._.user { inherit host; };
        in
        aspect.resolve ctx;

      users = map (user: {
        name = user.userName;
        value.imports = [ (hmUserModule user) ];
      }) hmUsers;

      hmModule = host.hm-module or inputs.home-manager."${class}Modules".home-manager;
      aspect.${class} = {
        imports = [ hmModule ];
        home-manager.users = lib.listToAttrs users;
      };

      supportedOS = builtins.elem class [
        "nixos"
        "darwin"
      ];
      enabled = supportedOS && builtins.length hmUsers > 0;
    in
    if enabled then aspect else { };

  aspect-option = import ../_aspect_option.nix { inherit inputs lib; };
in
{
  config.den = { inherit home-manager; };
  options.den.home-manager = aspect-option "home-managed OS";
}
