{ den, ... }:
{
  # user aspect
  den.aspects.tux = {
    includes = [
      den.provides.primary-user
      (den.provides.user-shell "fish")
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.htop ];
      };

    # user can provide NixOS configurations
    # to any host it is included on
    # nixos = { pkgs, ... }: { };
  };
}
