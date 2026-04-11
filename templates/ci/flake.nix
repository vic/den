{
  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      specialArgs = { inherit inputs; };
      modules = [ (inputs.import-tree ./modules) ];
    }).config.flake;

  inputs = {
    den.url = "github:vic/den";
    import-tree.url = "github:vic/import-tree";

    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    provider.url = "path:./provider";
    provider.inputs = {
      nixpkgs.follows = "nixpkgs";
      import-tree.follows = "import-tree";
      den.follows = "den";
    };
  };
}
