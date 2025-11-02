{ lib, den, ... }:
{
  den.provides.define-user.description = ''
    Defines user at OS and Home levels.

    ## Usage

       den.aspects.my-user._.user.includes = [
         den._.define-user
       ]

    for standalone-homes:

       den.aspects.my-home._.home.includes = [
         den._.define-user._.home
       ]

  '';

  den._.define-user.__functor =
    _:
    { user, host }:
    # deadnix: skip
    { class, ... }:
    let
      homeDir =
        if lib.hasSuffix "darwin" host.system then "/Users/${user.userName}" else "/home/${user.userName}";

      define-user = {
        nixos.users.users.${user.userName}.isNormalUser = true;
        darwin.users.users.${user.userName} = {
          name = user.userName;
          home = homeDir;
        };
        homeManager = {
          home.username = user.userName;
          home.homeDirectory = homeDir;
        };
      };
    in
    define-user;

  den._.define-user._.home.__functor =
    _:
    { home }:
    den._.define-user {
      user.userName = home.userName;
      host.system = home.system;
    };
}
