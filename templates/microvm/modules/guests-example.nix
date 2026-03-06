{ den, lib, ... }:
{

  den.hosts.x86_64-linux.server.microvm.guests = [
    den.hosts.x86_64-linux.guest-microvm
  ];

  den.hosts.x86_64-linux.guest-microvm = {
    intoAttr = [ ]; # dont produce Guest nixosConfiguration at flake output
  };

  den.aspects.no-boot.nixos = {
    boot.loader.grub.enable = false;
    fileSystems."/".device = "/dev/null";
  };

  den.aspects.server = {
    # USER TODO: remove this on real bootable server
    includes = [ den.aspects.no-boot ];

    # NOTE: no microvm class exist for Host, only for Guests
    nixos.microvm.host.startupTimeout = 300;
  };

  den.aspects.guest-microvm = {
    # resolved with: `(den.ctx.host = { host = guest-microvm }).resolve { class = "nixos" }`
    # resulting nixos-module is set at server: microvm.vms.<name>.config
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.cowsay ];
      };

    # microvm class is for Guests!, forwarded into server: nixos.microvm.vms.<name>
    microvm.autostart = true;
  };

}
