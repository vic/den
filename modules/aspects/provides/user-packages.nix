{ den, ... }:
let
  description = ''
    Includes a package at User and Home levels.

    Works in NixOS/Darwin and standalone Home-Manager

    ## Usage

       # for NixOS/Darwin
       den.aspects.my-user.includes = [ (den._.user-packages [ "hello" ]) ]

       # for standalone home-manager
       den.aspects.my-home.includes = [ den._.user-packages [ "hello" ]) ]

    or globally (automatically applied depending on context):

       den.default.includes = [ den._.user-packages [ "hello" ]) ]
  '';

  userPackages =
    pkgNames: user:
    let
      nixos = { pkgs, ... }: {
        users.users.${user.userName}.packages = map (pkgName: pkgs.${pkgName}) pkgNames;
      };
      darwin = { pkgs, ... }: {
        users.users.${user.userName}.packages = map (pkgName: pkgs.${pkgName}) pkgNames;
      };
      homeManager = { pkgs, ... }: {
        home.packages = map (pkgName: pkgs.${pkgName}) pkgNames;
      };
    in
    {
      inherit nixos darwin homeManager;
    };

in
{
  den.provides.user-packages =
    pkgNames:
    den.lib.parametric.exactly {
      inherit description;
      includes = [
        ({ host, user }: userPackages pkgNames user)
        ({ home }: userPackages pkgNames home)
      ];
    };
}