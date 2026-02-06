{
  inputs,
  lib,
  ns,
  # deadnix: skip
  __findFile ? __findFile,
  ...
}:
let
  treeModule.nixos.options.tree = lib.mkOption {
    type = lib.types.listOf lib.types.str;
  };
  inputX = {
    denful.ns.root = {
      nixos.tree = [ "X-root" ];
      provides.branch.nixos.tree = [ "X-branch" ];
      provides.branch.provides.leaf.nixos.tree = [ "X-leaf" ];
    };
  };
  inputY = {
    denful.ns.root = {
      nixos.tree = [ "Y-root" ];
      provides.branch.nixos.tree = [ "Y-branch" ];
      provides.branch.provides.leaf.nixos.tree = [ "Y-leaf" ];
    };
  };
in
{

  imports = [
    (inputs.den.namespace "ns" [
      true
      inputX
      inputY
    ])
  ];

  ns.root = {
    nixos.tree = [ "local-root" ];
    provides.branch.nixos.tree = [ "local-branch" ];
    provides.branch.provides.leaf.nixos.tree = [ "local-leaf" ];
  };

  den.aspects.rockhopper.includes = [
    treeModule
    <ns/root>
    <ns/root/branch>
    <ns/root/branch/leaf>
  ];

  perSystem =
    { checkCond, rockhopper, ... }:
    let
      vals = lib.sort (a: b: a < b) rockhopper.config.tree;
    in
    {
      checks.ns-angle-bracket-root = checkCond "angle-bracket access root" (<ns/root> == ns.root);

      checks.ns-angle-bracket-branch = checkCond "angle-bracket access branch" (
        <ns/root/branch> == ns.root._.branch
      );

      checks.ns-angle-bracket-leaf = checkCond "angle-bracket access leaf" (
        <ns/root/branch/leaf> == ns.root._.branch._.leaf
      );

      checks.ns-tree-all-levels-merged = checkCond "all tree levels merged" (
        vals == [
          "X-branch"
          "X-leaf"
          "X-root"
          "Y-branch"
          "Y-leaf"
          "Y-root"
          "local-branch"
          "local-leaf"
          "local-root"
        ]
      );
    };
}
