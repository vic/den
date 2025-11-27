# This flake is for testing by ci/namespace.nix
{ inputs, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];
  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "sim" true)
  ];

  sim.a._.b._.c._.d = {
    nixos.sims = [ "theirs abcd" ];
  };

  sim.ul._.a._.tion = {
    nixos.sims = [ "theirs simulation" ];
  };

}
