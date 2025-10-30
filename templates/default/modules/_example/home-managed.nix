{ den, ... }:
{
  # see batteries/home-manager.nix
  den.default.host._.host.includes = [ den.home-manager ];
}
