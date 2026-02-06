{ den, withSystem, ... }:
let
  testModule =
    {
      inputs',
      lib,
      self',
      ...
    }:
    {
      options.specialArgsTest = {
        test-package = lib.mkOption { type = lib.types.package; };
        neovim-package = lib.mkOption { type = lib.types.package; };
      };

      config.specialArgsTest = {
        test-package = self'.packages.hello;
        neovim-package = inputs'.neovim-nightly-overlay.packages.neovim;
      };
    };
in
{
  flake-file.inputs.neovim-nightly-overlay = {
    url = "github:nix-community/neovim-nightly-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-parts.follows = "flake-parts";
  };

  den.default.includes = [
    den._.self'
    den._.inputs'
  ];

  den.aspects.rockhopper.nixos.imports = [ testModule ];
  den.aspects.cam.homeManager.imports = [ testModule ];

  flake.checks.x86_64-linux = withSystem "x86_64-linux" (
    {
      checkCond,
      rockhopper,
      cam,
      self',
      inputs',
      ...
    }:
    {
      special-args-self-nixos = checkCond "self' provides same package to nixos" (
        rockhopper.config.specialArgsTest.test-package == self'.packages.hello
      );

      special-args-inputs-nixos = checkCond "inputs' provides same package to nixos" (
        rockhopper.config.specialArgsTest.neovim-package == inputs'.neovim-nightly-overlay.packages.neovim
      );

      special-args-self-hm = checkCond "self' provides same package to home-manager" (
        cam.config.specialArgsTest.test-package == self'.packages.hello
      );

      special-args-inputs-hm = checkCond "inputs' provides same package to home-manager" (
        cam.config.specialArgsTest.neovim-package == inputs'.neovim-nightly-overlay.packages.neovim
      );
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.hello = pkgs.hello;
    };
}
