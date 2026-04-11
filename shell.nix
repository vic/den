let
  lock = builtins.fromJSON (builtins.readFile ./templates/ci/flake.lock);
  nixpkgs =
    with lock.nodes.nixpkgs.locked;
    builtins.fetchTarball {
      url = "https://github.com/${owner}/${repo}/archive/refs/${rev}.zip";
      sha256 = narHash;
    };
in
{
  pkgs ? import nixpkgs { },
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
