let
  # Example: A static aspect for vm installers.
  vm-bootable = {
    nixos =
      { modulesPath, ... }:
      {
        imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
      };
  };
in
{
  den.default.includes = [
    # Example: static aspect
    vm-bootable
  ];
}
