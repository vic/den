{
  outputs = _: {
    flakeModule = ./nix/flakeModule.nix;
    templates.default = {
      path = ./templates/default;
      description = "Minimal nixos configuration";
    };
    packages.x86_64-linux.default = import ./nix/_vm.nix;
  };
}
