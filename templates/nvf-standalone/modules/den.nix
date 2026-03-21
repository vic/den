{
  inputs,
  den,
  lib,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];

  den.aspects.my-neovim =
    { mine }:
    {
      vim =
        { pkgs, ... }:
        {
          theme.enable = true;
          theme.name = "catppuccin";
          theme.style = if mine then "latte" else "frappe";
        };
    };

  # Expose my-neovim app. Runnable with `nix run .#my-neovim`.
  # Adapt if you use flake-parts or whatever
  flake.packages = lib.genAttrs lib.systems.flakeExposed (
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      # custom den.lib.nvf from ./nvf-integration.nix
      nvf = den.lib.nvf.package pkgs;
    in
    {
      my-neovim = nvf den.aspects.my-neovim { mine = true; };
      your-neovim = nvf den.aspects.my-neovim { mine = false; };
    }
  );
}
