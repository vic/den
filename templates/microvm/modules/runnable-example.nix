# Copied from MicroVM flake template.
#
# This is just a normal NixOS configuration that happes to include microvm.nix module.
# No special Den classes nor context pipeline here. It's all just a single NixOS conf.
# Den support: ./microvm-runners.nix
#
{
  inputs,
  den,
  lib,
  ...
}:
{

  den.hosts.x86_64-linux.runnable-microvm = {
    intoAttr = [
      "microvms"
      "runnable-microvm"
    ]; # example not intended to be used from nixosConfigurations
  };

  den.aspects.runnable-microvm = {
    nixos = {
      imports = [ inputs.microvm.nixosModules.microvm ];
      users.users.root.password = "";

      # There's not much need to have a forwarding microvm class for runnable vms
      microvm = {
        volumes = [
          {
            mountPoint = "/var";
            image = "var.img";
            size = 256;
          }
        ];
        shares = [
          {
            # use proto = "virtiofs" for MicroVMs that are started by systemd
            proto = "9p";
            tag = "ro-store";
            # a host's /nix/store will be picked up so that no
            # squashfs/erofs will be built for it.
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
        ];

        # "qemu" has 9p built-in!
        hypervisor = "qemu";
        socket = "control.socket";
      };
    };
  };
}
