{ den, ... }:
{
  # see batteries/home-manager.nix
  den.default.includes = [ den._.home-manager ];
}
