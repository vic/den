{ den, ... }:
{
  den.aspects.alice = {
    includes = [
      den._.primary-user
      den.aspects.shell
      den.aspects.hyprland
      den.aspects.dev-tools
    ];
    nixos = { ... }: { users.users.alice.isNormalUser = true; };
    homeManager = { pkgs, ... }: { home.packages = [ pkgs.git ]; };
  };
}
