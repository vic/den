{ inputs, ... }:
{
  # tux user on igloo host.
  den.hosts.x86_64-linux.igloo.users.tux = { };

  # host aspect
  den.aspects.igloo = {
    nixos =
      { pkgs, ... }:
      {
        # remove these for a real bootable host
        boot.loader.grub.enable = false;
        fileSystems."/".device = "/dev/fake";
        passthru = { };

        environment.systemPackages = [
          pkgs.vim
        ];
      };
  };

  # user aspect
  den.aspects.tux = {
    # user configures the host it lives in
    nixos = {
      # hipster-tux uses nix-maid instead of home-manager.
      imports = [ inputs.nix-maid.nixosModules.default ];

      users.users.tux = {
        isNormalUser = true;
        maid.file.home.".gitconfig".text = ''
          [user]
            name=Tux
        '';
      };
    };
  };
}
