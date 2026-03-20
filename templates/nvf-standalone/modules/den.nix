{
  inputs,
  den,
  lib,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];

  # a custom `vim` class that forwards to `nvf.config.vim`
  den.aspects.vimClass =
    { class, aspect-chain }:
    den._.forward {
      each = lib.singleton true;
      fromClass = _: "vim";
      intoClass = _: "nvf";
      intoPath = _: [
        "config"
        "vim"
      ];
      fromAspect = _: lib.head aspect-chain;
      adaptArgs = lib.id;
    };

  den.aspects.my-neovim = {
    includes = [ den.aspects.vimClass ];

    vim.theme.enable = true;
  };

  # Expose my-neovim app. Runnable with `nix run .#my-neovim`.
  # Adapt if you use flake-parts or whatever
  flake.legacyPackages = lib.genAttrs lib.systems.flakeExposed (
    system:
    let
      ctx = { }; # whatever context your aspects need
      aspect = den.aspects.my-neovim ctx;
      module = den.lib.aspects.resolve "nvf" [ ] aspect;

      nvf = inputs.nvf.lib.neovimConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        modules = [ module ];
      };
      my-neovim = nvf.neovim;
    in
    {
      inherit my-neovim;
    }
  );
}
