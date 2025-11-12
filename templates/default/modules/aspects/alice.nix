{ den, eg, ... }:
{
  den.aspects.alice = {
    # You can include other aspects, in this case some
    # den included batteries that provide common configs.
    includes = [
      eg.autologin
      den.provides.primary-user # alice is admin always.
      (den.provides.user-shell "fish") # default user shell
    ];

    # Alice configures NixOS hosts it lives on.
    nixos =
      { pkgs, ... }:
      {
        users.users.alice = {
          description = "Alice Cooper";
          packages = [ pkgs.vim ];
        };
      };

    # Alice home-manager.
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.htop ];
      };
  };
}
