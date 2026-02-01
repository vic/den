let

  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      modules = [ (inputs.import-tree ./modules) ];
      specialArgs = {
        inherit inputs;
        inherit (inputs) self;
      };
    }).config;

in
# Den outputs configurations at flake top-level attr
# even when it does not depend on flakes or flake-parts.
(import ./with-inputs.nix outputs).flake
