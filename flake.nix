{
  outputs = _: {
    flakeModule = ./nix/flakeModule.nix;
    templates.default = {
      path = ./templates/default;
      description = "Example configuration";
    };
    templates.minimal = {
      path = ./templates/minimal;
      description = "Minimal configuration";
    };
    packages = import ./nix/template-packages.nix;
    namespace = import ./nix/namespace.nix;
    lib = import ./nix/lib.nix;
  };
}
