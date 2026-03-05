{ den, inputs, ... }:
{
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  den.default.nixos = {
    # remove for real host
    fileSystems."/".device = "/dev/fake";
    boot.loader.grub.enable = false;
  };

  # tux user on igloo host, using nix-maid
  den.hosts.x86_64-linux.igloo.users.tux.classes = [ "maid" ];
  # tux on iceberg host with NixOS user environment
  den.hosts.x86_64-linux.iceberg.users.tux.classes = [ "user" ];

  # first: `npins add -n darwin github nix-darwin nix-darwin`
  # den.hosts.aarch64-darwin.apple.users.tux.classes = [ "hjem" ];

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
    # den batteries or your own re-usable aspects
    includes = [ den.provides.define-user ];

    # user configures host <nixos/darwin>.users.users.tux.description
    # Read docs about the `user` class.
    user.description = "Cute Penguin";

    # user contributes nixos and darwin common config
    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.hello ];
      };

    # maid class
    maid.file.home.".gitconfig".text = ''
      [user]
        name=Tux
    '';
  };
}
