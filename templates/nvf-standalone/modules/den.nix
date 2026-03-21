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
      vim.theme.enable = true;
      vim.theme.name = "catppuccin";
      vim.theme.style = if mine then "latte" else "mocha";
    };

  den.lib.nvfModule =
    vimAspect: ctx:
    let
      # a custom `vim` class that forwards to `nvf.vim`
      vimClass =
        { class, aspect-chain }:
        den._.forward {
          each = lib.singleton true;
          fromClass = _: "vim";
          intoClass = _: "nvf";
          intoPath = _: [
            "vim"
          ];
          fromAspect = _: lib.head aspect-chain;
          adaptArgs = lib.id;
        };

      aspect = den.lib.parametric.fixedTo ctx {
        includes = [
          vimClass
          vimAspect
        ];
      };

      module = den.lib.aspects.resolve "nvf" [ aspect ] aspect;
    in
    module;

  # Expose my-neovim app. Runnable with `nix run .#my-neovim`.
  # Adapt if you use flake-parts or whatever
  flake.packages = lib.genAttrs lib.systems.flakeExposed (
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      nvf =
        aspect: ctx:
        (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ (den.lib.nvfModule aspect ctx) ];
        }).neovim;
    in
    {
      my-neovim = nvf den.aspects.my-neovim { mine = true; };
      your-neovim = nvf den.aspects.my-neovim { mine = false; };
    }
  );
}
