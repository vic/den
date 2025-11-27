# This flake is for testing by ci/namespace.nix
{ inputs, ours, ... }:
{
  systems = [ "x86_64-linux" "aarch64-darwin" ];
  imports = [ 
    inputs.den.flakeModule 
    (inputs.den.namespace "sim" true)
  ];

  sim.a._.b._.c._.d = {
    description = "abcd";
    nixpks.sims = [ "theirs abcde" ];
  };

  sim.ul._.a._.tion.nixos.sims = [ "theirs simulation" ];

}
