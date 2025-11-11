{ lib, ... }:
{
  imports =
    let
      files = builtins.readDir ./checkmate/tests;
      names = builtins.attrNames files;
      nixes = builtins.filter (lib.hasSuffix ".nix") names;
      tests = map (file: "${./checkmate/tests}/${file}") nixes;
    in
    tests;

  perSystem.treefmt.settings.global.excludes = [ ".github/*/*.md" ];
}
