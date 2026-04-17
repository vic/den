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

    # <host>.provides.<user>, via den.provides.mutual-provider
    provides.alice =
      { user, ... }:
      {
        homeManager.programs.tmux.enable = user.name == "alice";
      };
  };
}
