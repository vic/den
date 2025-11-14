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
    { OS, host }:
    { class, aspect-chain }:
    let
      hmClass = "homeManager";
      hmUsers = builtins.filter (u: u.class == hmClass) (lib.attrValues host.users);

      hmUserModule =
        user:
        let
          ctx = {
            inherit aspect-chain;
            class = hmClass;
          };
          HM = den.aspects.${user.aspect};
          aspect = HM {
            inherit host user;
            OS-HM = { inherit OS HM; };
          };
          module = aspect.resolve ctx;
        in
        module;

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

in
{
  den.provides.home-manager = {
    inherit description;
    __functor = _: den.lib.take.exactly homeManager;
  };
}
