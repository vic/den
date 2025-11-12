{
  # make USB/VM installers.
  eg.vm-bootable.nixos =
    { modulesPath, ... }:
    {
      imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix") ];
    };
}
