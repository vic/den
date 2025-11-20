{
  outputs = _: {
    flakeModule = ./nix/flakeModule.nix;
    templates = {
      default.path = ./templates/default;
      default.description = "Batteries included";
      minimal.path = ./templates/minimal;
      minimal.description = "Minimalistic den";
      examples.path = ./templates/examples;
      examples.description = "API examples and CI";
      bogus.path = ./templates/bogus;
      bogus.description = "For bug reproduction";
    };
    packages = import ./nix/template-packages.nix;
    namespace = import ./nix/namespace.nix;
    lib = import ./nix/lib.nix;
  };
}
