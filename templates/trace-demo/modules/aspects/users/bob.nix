{ den, ... }:
{
  den.aspects.bob = {
    includes = [
      den._.primary-user
      den.aspects.gnome
      den.aspects.dev-tools
    ];
    nixos = { ... }: { users.users.bob.isNormalUser = true; };
    homeManager = { pkgs, ... }: { home.packages = [ pkgs.firefox ]; };
  };
}
