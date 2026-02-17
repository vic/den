{ inputs, ... }:
{
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  den.default.nixos = {
    # remove for real host
    fileSystems."/".device = "/dev/fake";
    boot.loader.grub.enable = false;
  };

  # tux user on igloo host.
  den.hosts.x86_64-linux.igloo.users.tux = { };

  # host aspect
  den.aspects.igloo = {
    nixos =
      { pkgs, ... }:
      {
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
