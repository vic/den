{
  pkgs ? import <nixpkgs> { },
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
