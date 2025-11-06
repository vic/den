{ lib, den, ... }:
let
  description = ''
    Defines a user at OS and Home levels.

    Works in NixOS/Darwin and standalone Home-Manager

    ## Usage

       # for NixOS/Darwin
       den.aspects.my-user.includes = [ den._.define-user ]

       # for standalone home-manager
       den.aspects.my-home.includes = [ den._.define-user ]

    or globally (automatically applied depending on context):

       den.default.includes = [ den._.define-user ]
  '';

  homeDir =
    host: user:
    if lib.hasSuffix "darwin" host.system then "/Users/${user.userName}" else "/home/${user.userName}";

  userToHostContext =
    { fromUser, toHost }:
    {
      nixos.users.users.${fromUser.userName}.isNormalUser = true;
      darwin.users.users.${fromUser.userName} = {
        name = fromUser.userName;
        home = homeDir toHost fromUser;
      };
    };

  userContext =
    { host, user }:
    {
      homeManager = {
        home.username = user.userName;
        home.homeDirectory = homeDir host user;
      };
    };

  hmContext =
    { home }:
    userContext {
      host.system = home.system;
      user.userName = home.userName;
    };
in
{
  den.provides.define-user = {
    inherit description;
    includes = [
      userToHostContext
      userContext
      hmContext
    ];
    __functor = den.lib.parametric true;
  };
}
