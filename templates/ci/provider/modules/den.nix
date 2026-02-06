{ inputs, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "provider" true)
  ];

  provider.tools._.dev._.editors = {
    description = "Editor configurations from provider flake";
    nixos.environment.variables.PROVIDER_EDITOR = "vim";
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vim ];
      };
  };

  provider.tools._.dev._.shells = {
    description = "Shell configurations from provider flake";
    nixos.environment.variables.PROVIDER_SHELL = "fish";
    nixos.environment.systemPackages = [ ];
  };
}
