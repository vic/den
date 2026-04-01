{ inputs, lib, ... }:
{
  flake-file.inputs.den.url = lib.mkDefault "github:vic/den";
  imports = [ (inputs.den.flakeModule or { }) ];
}
