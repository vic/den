{ den, eg, ... }:
{
  den.aspects.igloo = {
    # igloo host provides some home-manager defaults to its users.
    homeManager.programs.direnv.enable = true;

    # NixOS configuration for igloo.
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.hello ];
      };

    # Include aspects from the eg namespace
    includes = [
      eg.vm-bootable
      eg.xfce-desktop
    ];
  };
}
