# The best practice is to split this file into several modules,
# creating a directory structure inside `modules/` that makes sense to you.
# See: https://vic.github.io/dendrix/Dendritic.html#no-file-organization-restrictions
{ den, config, ... }:
{

  # First, lets define a NixOS, a nix-darwin and standalone home-manager.
  # Feel free to remove, rename or add any other definition.
  # NOTE: for nix-darwin/home-manager to work we added dependencies at dendritic.nix.

  # both hosts `igloo` and `apple` have a single user in this setup.
  # since user aspect `alice` is the same, they share home configurations.
  den.hosts.x86_64-linux.igloo.users.alice = { };
  den.hosts.aarch64-darwin.apple.users.alice = { };

  # an standalone home-manager configuration sharing `alice` aspect.
  # den.homes.aarch64-darwin.alice = { };

  # Now, lets create some aspects and later include them in our host and user aspects.
  #
  # Aspects can be defined on let-bindings, or be part of `den.aspects` tree.
  # Use let bindings for SMALL one-shot aspects, and an aspect tree for more
  # complex and re-usable ones.

  # We define this one inside the `common.provides` aspect tree.
  # Please organize your aspects with names that make sense to you
  # and on their own directories and modules.
  den.aspects.common.provides = {

    # xfce-desktop is a non-parametric aspect. it does not uses context
    # for how to behave, it must be included explicitly on a host.
    xfce-desktop.nixos =
      { lib, ... }:
      {
        # https://gist.github.com/nat-418/1101881371c9a7b419ba5f944a7118b0
        services.xserver = {
          enable = true;
          desktopManager = {
            xterm.enable = false;
            xfce.enable = true;
          };
        };

        services.displayManager = {
          defaultSession = lib.mkDefault "xfce";
          enable = true;
        };
      };

    # autologin is context-aware, parametric aspect.
    # it applies only if the context has at least { user }
    # meaning that has access to user data
    autologin =
      { user, ... }:
      {
        nixos =
          { config, lib, ... }:
          lib.mkIf config.services.displayManager.enable {
            services.displayManager.autoLogin.enable = true;
            services.displayManager.autoLogin.user = user.userName;
          };
      };

    # This one can be included on igloo host to make USB/VM installers.
    vm-bootable =
      { host, ... }:
      {
        nixos =
          { modulesPath, ... }:
          {
            networking.hostName = host.hostName;
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix") ];
          };
      };
  };

  den.aspects.igloo.includes =
    let
      # an small parametric aspect that needs access to contextual host data.
      hostname =
        { host, ... }:
        {
          nixos.networking.hostName = host.name;
        };
    in
    [
      hostname
      den.aspects.common._.vm-bootable
      den.aspects.common._.xfce-desktop
    ];

  # NixOS configuration for igloo.
  den.aspects.igloo.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.hello ];
    };

  # igloo host provides some home-manager defaults to its users.
  den.aspects.igloo.homeManager.programs.direnv.enable = true;

  den.aspects.alice = {
    # You can include other aspects, in this case some
    # den included batteries that provide common configs.
    includes = [
      den.aspects.common._.autologin
      den.provides.primary-user # alice is admin always.
      (den.provides.user-shell "fish") # default user shell
    ];

    # Alice configures NixOS hosts it lives on.
    nixos =
      { pkgs, ... }:
      {
        users.users.alice = {
          description = "Alice Cooper";
          packages = [ pkgs.vim ];
        };
      };

    # Alice home-manager.
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.htop ];
      };
  };

  # Lets also configure some defaults using aspects.
  # These are global static settings.
  den.default = {
    darwin.system.stateVersion = 6;
    nixos.system.stateVersion = "25.05";
    homeManager.home.stateVersion = "25.05";
  };

  # These are functions that produce configs
  den.default.includes = [
    # Enable home-manager on all hosts.
    den.provides.home-manager

    # Automatically create the user on host.
    den.provides.define-user

    # Disable booting when running on CI on all NixOS hosts.
    (if config ? _module.args.CI then den.aspects.ci-no-boot else { })
  ];

  den.aspects.ci-no-boot = {
    description = "Disables booting during CI";
    nixos = {
      boot.loader.grub.enable = false;
      fileSystems."/".device = "/dev/null";
    };
  };

}
