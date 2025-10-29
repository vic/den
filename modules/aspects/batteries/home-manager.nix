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

        den.aspects.my-host.includes = [ (den.home-manager { host = den.hosts.<system>.my-host; }) ];

      for enabling home-manager by default on all hosts:

        den.default.host.includes = [ den.home-manager ];

    Does nothing for hosts that have no users with `homeManager` class.
    Expects `inputs.home-manager` to exist. If `<host>.hm-input` exists
    it is the name of the input to use instead of `home-manager`.

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
        den.aspects.${user.aspect}.resolve {
          inherit aspect-chain;
          class = "homeManager";
        };

      users = map (user: {
        name = user.userName;
        value.imports = [ (hmUserModule user) ];
      }) hmUsers;

      hmModule = inputs.${host.hm-input or "home-manager"}."${class}Modules".home-manager;
      aspect.${class} = {
        imports = [ hmModule ];
        home-manager.users = lib.listToAttrs users;
      };

      supportedHmOS = builtins.elem class [
        "nixos"
        "darwin"
      ];
      enabled = supportedHmOS && builtins.length hmUsers > 0;
    in
    if enabled then aspect else { };

  aspect-option = import ../_aspect_option.nix { inherit inputs lib; };
in
{
  config.den = { inherit home-manager; };
  options.den.home-manager = aspect-option "home-managed OS";
}
