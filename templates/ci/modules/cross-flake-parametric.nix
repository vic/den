{
  inputs,
  lib,
  provider,
  ...
}:
let
  providerModule.nixos.options.providerVars = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
  };
in
{
  flake-file.inputs.provider = {
    url = "path:./provider";
    inputs.den.follows = "den";
    inputs.flake-aspects.follows = "flake-aspects";
    inputs.flake-parts.follows = "flake-parts";
    inputs.import-tree.follows = "import-tree";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [
    (inputs.den.namespace "provider" [
      true
      inputs.provider
    ])
  ];

  provider.tools._.dev._.editors = {
    nixos.providerVars.LOCAL_EDITOR = "emacs";
  };

  den.aspects.rockhopper.includes = [
    providerModule
    provider.tools._.dev._.editors
    provider.tools._.dev._.shells
  ];

  perSystem =
    { checkCond, rockhopper, ... }:
    let
      vars = rockhopper.config.providerVars;
      env = rockhopper.config.environment.variables;
    in
    {
      checks.cross-flake-provider-editor = checkCond "provider editor var set" (
        env.PROVIDER_EDITOR == "vim"
      );

      checks.cross-flake-provider-shell = checkCond "provider shell var set" (
        env.PROVIDER_SHELL == "fish"
      );

      checks.cross-flake-local-editor = checkCond "local editor var set" (vars.LOCAL_EDITOR == "emacs");

      checks.cross-flake-namespace-merged = checkCond "namespace merged from provider input" (
        provider.tools._.dev._.editors == inputs.self.denful.provider.tools._.dev._.editors
        && provider.tools._.dev._.shells == inputs.self.denful.provider.tools._.dev._.shells
      );

      checks.cross-flake-input-denful = checkCond "input provider denful accessible" (
        inputs.provider.denful.provider.tools._.dev._.editors.description
        == "Editor configurations from provider flake"
      );
    };
}
