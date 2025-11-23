{
  inputs,
  den,
  lib,
  eg,
  # deadnix: skip
  __findFile ? __findFile,
  ...
}:
let
  # module for testing inclusion of namespaces
  simsModule.nixos.options.sims = lib.mkOption {
    type = lib.types.listOf lib.types.str;
  };
in
{
  # enable <angle/bracket> syntax for finding aspects.
  _module.args.__findFile = den.lib.__findFile;

  imports = [
    # create a local namespace and output at flake.denful.eg
    (inputs.den.namespace "eg" true)

    # you can also mount a namespace from many input sources.
    # the second argument becomes an array of inputs.
    (
      let
        # NOTE: here we simulate inputA and inputB are flakes.
        inputA.denful.sim.ul._.a._.tion.nixos.sims = [ "from inputA" ];
        inputB.denful.sim.ul._.a._.tion.nixos.sims = [ "from inputB" ];
        exposeToFlake = true;
      in
      inputs.den.namespace "sim" [
        inputA
        inputB
        exposeToFlake
      ]
    )
  ];

  # define nested aspects in local namespace
  eg.foo.provides.bar.provides.baz = {
    nixos.sims = [ "local <eg/foo/bar/baz>" ];
  };

  # augment aspects on a mounted namespace
  sim.ul._.a._.tion.nixos.sims = [ "augmented <sim/ul/a/tion>" ];

  den.aspects.rockhopper.includes = [
    simsModule
    <eg/foo/bar/baz>
    <sim/ul/a/tion>
  ];

  perSystem =
    { checkCond, rockhopper, ... }:
    {
      checks.namespace-eg-flake-output = checkCond "namespace enabled as flake output" (
        eg == den.ful.eg && eg == <eg> && eg == inputs.self.denful.eg
      );

      checks.namespace-eg-provides-accessible = checkCond "exact same value" (
        eg.foo._.bar._.baz == <eg/foo/bar/baz>
        && eg.foo._.bar._.baz == inputs.self.denful.eg.foo._.bar._.baz
      );

      checks.namespace-sim-merged = checkCond "merges from all sources" (
        let
          expected = [
            "augmented <sim/ul/a/tion>"
            "from inputA"
            "from inputB"
            "local <eg/foo/bar/baz>"
          ];
          actual = lib.sort (a: b: a < b) rockhopper.config.sims;
        in
        expected == actual
      );

    };
}
