{ inputs, den, ... }:
{
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.igloo.users.tux = { };

  den.aspects.igloo = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.hello ];

        # USER TODO: remove this
        boot.loader.grub.enable = false;
        fileSystems."/".device = "/dev/null";
      };
  };

  den.aspects.tux = {
    includes = [ den.provides.primary-user ];
  };
}
