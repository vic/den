{
  inputs.target.url = "path:..";
  inputs.checkmate.url = "github:vic/checkmate";
  inputs.checkmate.inputs.target.follows = "target";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  outputs = inputs: inputs.checkmate.lib.newFlake;
}
