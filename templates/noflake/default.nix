let

  modules =
    { inputs, ... }:
    {
      imports = [ (inputs.import-tree ./modules) ];
    };

  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      modules = [ modules ];
      specialArgs = {
        inherit inputs;
        inherit (inputs) self;
      };
    }).config;

in
import ./with-inputs.nix outputs
