{ den, ... }:
{
  # see batteries/home-manager.nix
  den.default.host.includes = [ den.home-manager ];
}
