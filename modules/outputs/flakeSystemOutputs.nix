{
  den,
  lib,
  options,
  inputs,
  ...
}:
let
  ctx.flake.into.flake-system = _: map (system: { inherit system; }) den.systems;

  systemOutput = output: { system }: lib.singleton { inherit system output; };

  has-flake-output =
    output: ((options.flake.type.getSubOptions or (_: options.flake)) { }) ? ${output};

  systemOutputFwd =
    { system, output }:
    { class, ... }:
    den.provides.forward {
      each = lib.optional (class == "flake") output;
      fromClass = _: output;
      intoClass = _: "flake";
      intoPath = _: [
        "flake"
        output
        system
      ];
      guard = _: has-flake-output output;
      adaptArgs = _: { pkgs = inputs.nixpkgs.legacyPackages.${system}; };
    };

  ctxSystemOuts =
    let
      outputs = [
        "packages"
        "apps"
        "checks"
        "devShells"
        "legacyPackages"
      ];

      ctxs = map (output: {
        flake-system.into."flake-${output}" = systemOutput output;
        flake-system.provides."flake-${output}" = _: systemOutputFwd;
      }) outputs;
    in
    ctxs;

in
{
  den.ctx = lib.mkMerge (ctxSystemOuts ++ [ ctx ]);
}
