# Provides shell utilities under `den.sh` for building OS configurations using
# github:nix-community/nh instead of nixos-rebuild, etc
{
  lib,
  den,
  inputs,
  ...
}:
{
  options.den.sh = lib.mkOption {
    description = "Non-flake Den shell environment";
    default = den.lib.nh.denShell {
      fromFlake = false;
      outPrefix = [ "flake" ];
    } (import inputs.nixpkgs { });
  };
}
