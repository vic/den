{
  den,
  lib,
  withSystem,
  inputs,
  ...
}:
{
  # we use another unfree-host and unfree-user because
  # unlike rockhopper, we need useGlobalPkgs=false for hm test.
  den.hosts.x86_64-linux.unfree-host.users.unfree-user = { };
  # for testing home-manager nixpkgs.config:
  den.aspects.unfree-host.nixos.home-manager.useGlobalPkgs = false;

  den.aspects.testingInputs'.homeManager =
    { inputs', ... }:
    {
      home.packages = [ inputs'.nixpkgs.legacyPackages.cowsay ];
    };

  den.aspects.testingSelf'.homeManager =
    { self', ... }:
    {
      home.packages = [ self'.packages.bye ];
    };

  den.aspects.testingUnfree.includes = [
    (den._.unfree [ "example-unfree-package" ])
    {
      homeManager =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.hello-unfree ];
        };
    }
  ];

  # including on user was causing duplicate definitions.
  den.aspects.unfree-user.includes = [
    den.aspects.testingInputs'
    den.aspects.testingSelf'
    den.aspects.testingUnfree
  ];

  flake.checks.x86_64-linux = withSystem "x86_64-linux" (
    {
      pkgs,
      checkCond,
      ...
    }:
    let
      host = inputs.self.nixosConfigurations.unfree-host.config;
      user = host.home-manager.users.unfree-user;

      names = map lib.getName user.home.packages;
      inputsCheck = builtins.elem "cowsay" names;
      selfCheck = builtins.elem "hello" names;

      useGlobalPkgs = host.home-manager.useGlobalPkgs;
      unfreeCheck = user.nixpkgs.config.allowUnfreePredicate pkgs.hello-unfree;
    in
    {
      unfree-user-has-self-bye = checkCond "self bye" selfCheck;
      unfree-user-has-inputs-cowsay = checkCond "inputs cowsay" inputsCheck;
      unfree-user-hm-unfree = checkCond "hm unfree" ((!useGlobalPkgs) && unfreeCheck);
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.bye = pkgs.hello;
    };
}
