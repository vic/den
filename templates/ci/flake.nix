{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    den.url = "github:vic/den";
    flake-aspects.url = "github:vic/flake-aspects";
    import-tree.url = "github:vic/import-tree";

    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    nix-unit.url = "github:nix-community/nix-unit";
    nix-unit.inputs = {
      flake-parts.follows = "flake-parts";
      nix-github-actions.follows = "";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "";
    };

    provider.url = "path:./provider";
    provider.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      flake-aspects.follows = "flake-aspects";
      import-tree.follows = "import-tree";
      den.follows = "den";
    };
  };
}
