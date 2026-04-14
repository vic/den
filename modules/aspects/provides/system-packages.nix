{ den, ... }:
let
  description = ''
    Includes a package at System levels.

    Works in NixOS/Darwin

    ## Usage

       # for NixOS/Darwin
       den.aspects.my-laptop.includes = [ (den._.system-packages [ "hello" ]) ]

    or globally (automatically applied depending on context):

       den.default.includes = [ den._.system-packages [ "hello" ]) ]
  '';
  
  systemPackages =
    getPkgs: user:
    let
      nixos = { pkgs, ... }: {
        environment.systemPackages = getPkgs pkgs;
      };
      darwin = nixos;
    in
    {
      inherit nixos darwin;
    };

in
{
  den.provides.system-packages =
    getPkgs:
    den.lib.parametric.exactly {
      inherit description;
      includes = [
        ({ host }: systemPackages getPkgs)
      ];
    };
}