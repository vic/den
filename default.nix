{
  __functor = self: import ./nix/lib.nix;
  nixModule =
    inputs:
    { config, lib, ... }:
    let
      den-lib = import ./nix/lib.nix { inherit inputs config lib; };
    in
    {
      imports = [ den-lib.nixModule ];
    };
}
