{
  outputs = _: {
    flakeModule = ./nix/flakeModule.nix;
    templates = {
      default.path = ./templates/default;
      default.description = "Example configuration";
      minimal.path = ./templates/minimal;
      minimal.description = "Minimal configuration";
      bogus.path = ./templates/bogus;
      bogus.description = "For bug reproduction";
    };
    packages = import ./nix/template-packages.nix;
    namespace = import ./nix/namespace.nix;
    lib = import ./nix/lib.nix;
  };
}
