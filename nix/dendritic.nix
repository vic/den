{ inputs, lib, ... }:
{

  flake-file.inputs.flake-aspects.url = lib.mkDefault "github:vic/flake-aspects";
  flake-file.inputs.den.url = lib.mkDefault "github:vic/den";

  imports = [
    (inputs.den.flakeModule or { })
  ];

}
