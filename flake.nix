{
  outputs = _: {
    flakeModule = ./nix/flakeModule.nix;
    templates.default = {
      path = ./templates/default;
      description = "Minimal nixos configuration";
    };
    packages = import ./nix/template-packages.nix;
  };
}
