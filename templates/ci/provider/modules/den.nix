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
    nixos.programs.vim.enable = true;
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vim ];
      };
  };
}
