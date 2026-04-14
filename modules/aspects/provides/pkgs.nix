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

  hostPackages =
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

  userPackages =
    getPkgs: user:
    let
      nixos = { pkgs, ... }: {
        users.users.${user.userName}.packages = getPkgs pkgs;
      };
      darwin = nixos;
    in
    {
      inherit nixos darwin;
    };

  homePackages =
    getPkgs:
    let
      homeManager = { pkgs, ... }: {
        home.packages = getPkgs pkgs;
      };
    in
    {
      inherit homeManager;
    };

  to-host = getPkgs: ({ host }: hostPackages getPkgs);
  to-user = getPkgs: ({ host, user }: userPackages getPkgs user);
  to-home = getPkgs: ({ home }: homePackages getPkgs);

in
{
  den.provides.pkgs =
    getPkgs: den.lib.parametric {
      inherit description;
      includes = [
        (to-host getPkgs)
        (to-user getPkgs)
        (to-home getPkgs)
      ];
    };
}