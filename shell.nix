let
  lock = builtins.fromJSON (builtins.readFile ./templates/ci/flake.lock);
  nixpkgs =
    with lock.nodes.nixpkgs.locked;
    builtins.fetchTarball {
      url = url;
      hash = narHash;
    };
in
{
  pkgs ? nixpkgs,
  lib ? pkgs.lib,
  ...
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    just
    nix-unit
    npins
    pnpm
    nodejs
    hyperfine
  ];
}
