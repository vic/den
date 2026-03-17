let
  rev = "9100a0f";
  narHash = "sha256:09m84vsz1py50giyfpx0fpc7a4i0r1xsb54dh0dpdg308lp4p188";
  compat = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${rev}.tar.gz";
    sha256 = narHash;
  };

  flake = import compat { src = ../templates/example; };
  lib = import (flake.outputs.inputs.nixpkgs + "/lib");
  eachSystem = lib.genAttrs lib.systems.flakeExposed;

  packages = eachSystem (system: {
    default = flake.outputs.packages.${system}.vm;
  });

  devShells = eachSystem (system: {
    default = import ../shell.nix {
      pkgs = import flake.outputs.inputs.nixpkgs { inherit system; };
    };
  });
in
{
  inherit packages devShells;
}
