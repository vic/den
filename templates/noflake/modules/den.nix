{ inputs, ... }:
{
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  den.default.nixos = {
    # remove for real host
    fileSystems."/".device = "/dev/fake";
    boot.loader.grub.enable = false;
  };

  # tux user on igloo host, using nix-maid
  den.hosts.x86_64-linux.igloo.users.tux = {
    classes = [ "maid" ];
  };

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
    # user configures host nixos.users.users.tux.isNormalUser.
    # Read docs about the `user` class.
    user.isNormalUser = true;

    # maid class
    maid.file.home.".gitconfig".text = ''
      [user]
        name=Tux
    '';
  };
}
