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

  # Parametric { host, user } => aspect.
  # Configures at OS and HM levels. For NixOs and Darwin.
  osUser =
    { host, user }:
    {
      nixos.users.users.${user.userName}.isNormalUser = true;
      darwin.users.users.${user.userName} = {
        name = user.userName;
        home = homeDir host user;
      };
      homeManager = {
        home.username = user.userName;
        home.homeDirectory = homeDir host user;
      };
    };

  # Parametric { home } => aspect.
  hmUser =
    { home }:
    osUser {
      user.userName = home.userName;
      host.system = home.system;
    };
in
{
  den.provides.define-user = {
    inherit description;
    includes = [
      osUser
      hmUser
    ];
    __functor = den.lib.parametric true;
  };
}
