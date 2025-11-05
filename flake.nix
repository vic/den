{
  outputs = _inputs: {
    flakeModule = ./nix/flakeModule.nix;
    templates.default = {
      path = ./templates/default;
      description = "Minimal nixos configuration";
    };
    packages = import ./nix/template-packages.nix;
    lib = import ./nix/lib.nix;
  };
}
