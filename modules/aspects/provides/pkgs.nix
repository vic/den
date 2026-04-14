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
    getPkgs: user:
    let
      nixos = { pkgs, ... }: {
        users.users.${user.userName}.packages = getPkgs pkgs;
      };
      darwin = nixos;
      homeManager = { pkgs, ... }: {
        home.packages = getPkgs pkgs;
      };
    in
    {
      inherit nixos darwin homeManager;
    };
  
  systemPackages =
    getPkgs:
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
  den.provides.pkgs =
    getPkgs: den.lib.parametric {
      inherit description;
      includes = [
        ({ host }: systemPackages getPkgs)
        ({ user }: userPackages getPkgs user)
        ({ home }: userPackages getPkgs home)
      ];
    };
}