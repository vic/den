{
  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      modules = [ (inputs.import-tree ./modules) ];
      specialArgs = { inherit inputs; };
    }).config.flake;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.11";
    import-tree.url = "github:vic/import-tree";
    den.url = "github:vic/den";
  };
}
