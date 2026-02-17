{
  inputs,
  lib,
  den,
  ...
}:
let
  description = ''
    integrates home-manager into nixos/darwin OS classes.

    usage:

      for using home-manager in just a particular host:

        den.aspects.my-laptop.includes = [ den._.home-manager ];

      for enabling home-manager by default on all hosts:

        den.default.includes = [ den._.home-manager ];

    Does nothing for hosts that have no users with `homeManager` class.
    Expects `inputs.home-manager` to exist. If `<host>.hm-module` exists
    it is the home-manager.{nixos/darwin}Modules.home-manager.

    For each user resolves den.aspects.''${user.aspect} and imports its homeManager class module.
  '';

  homeManager =
    { HM-OS-HOST }:
    let
      inherit (HM-OS-HOST) OS host;

      hmClass = "homeManager";
      hmModule = host.hm-module or inputs.home-manager."${host.class}Modules".home-manager;
      hmUsers = lib.filter (u: u.class == hmClass) (lib.attrValues host.users);

      hmUserAspect =
        user:
        let
          HM = den.aspects.${user.aspect};
          HM-OS-USER = {
            inherit
              OS
              HM
              host
              user
              ;
          };
        in
        HM { inherit HM-OS-USER; };

      hmUsersAspect =
        { class, aspect-chain }:
        den._.forward {
          each = lib.optionals (lib.elem class [
            "nixos"
            "darwin"
          ]) hmUsers;
          fromClass = _: hmClass;
          fromAspect = den.lib.take.unused aspect-chain hmUserAspect;
          intoClass = _: class;
          intoPath = user: [
            "home-manager"
            "users"
            user.userName
          ];
        };
    in
    {
      ${host.class}.imports = [ hmModule ];
      includes = [ hmUsersAspect ];
    };

in
{
  den.provides.home-manager = {
    inherit description;
    __functor = _: den.lib.take.exactly homeManager;
  };
}
