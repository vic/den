# Feel free to remove this file, adapt or split into modules.
#
# NOTE: This file does not reflect best organization practices,
# for that see the _profile directory.
#
# These examples exercice all den features, use them as reference
# of usage.
# See ci.nix for checks.
# See defaults.nix, and other files in _example/*.nix
{
  inputs,
  lib,
  den,
  ...
}:
let

  # Example: A static aspect for vm installers.
  vm-bootable = {
    nixos =
      { modulesPath, ... }:
      {
        imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
      };
  };

  # Example: parametric host aspect to automatically set hostName on any host.
  set-host-name =
    { host, ... }:
    {
      ${host.class}.networking.hostName = host.name;
    };

  # Example: installed on den.defaults for each user contribute into host.
  one-hello-package-for-each-user =
    { userToHost, ... }:
    {
      ${userToHost.host.class} =
        { pkgs, ... }:
        {
          users.users.${userToHost.user.userName}.packages = [ pkgs.hello ];
        };
    };

  # Example: configuration that depends on both host and user. provides to the host.
  user-to-host-conditional =
    { userToHost, ... }:
    if userToHost.user.userName == "alice" && !lib.hasSuffix "darwin" userToHost.host.system then
      {
        nixos.programs.tmux.enable = true;
      }
    else
      { };

  # Example: configuration that depends on both host and user. provides to the host.
  host-to-user-conditional =
    { hostToUser, ... }:
    if hostToUser.user.userName == "alice" && !lib.hasSuffix "darwin" hostToUser.host.system then
      {
        homeManager.programs.git.enable = true;
      }
    else
      { };

  # Example: luke standalone home-manager has access to rockhopper osConfig specialArg.
  os-conditional-hm =
    { home }:
    {
      # access osConfig, wired via extraSpecialArgs in homes.nix.
      homeManager =
        { osConfig, ... }:
        {
          programs.bat.enable = osConfig.programs.${home.programToDependOn}.enable;
        };
    };

in
{
  den.default.includes = [
    # Example: static aspect
    vm-bootable

    # Example: parametric { host } aspect
    set-host-name

    # Example: parametric { fromUser, toHost } aspect.
    one-hello-package-for-each-user

    # Example: parametric over many contexts: { home }, { host, user }, { fromUser, toHost }
    den.provides.define-user
  ];

  # Example: user provides static config to all its nixos hosts.
  den.aspects.alice.nixos.users.users.alice.description = "Alice Q. User";

  # Example: host provides static config to all its users hm.
  den.aspects.rockhopper.homeManager.programs.direnv.enable = true;

  # Example: adelie host using github:nix-community/NixOS-WSL
  den.aspects.adelie.nixos = {
    imports = [ inputs.nixos-wsl.nixosModules.default ];
    wsl.enable = true;
  };

  # Example: enable helix for alice on all its home-managed hosts.
  den.aspects.alice.homeManager.programs.helix.enable = true;

  # can uses unfree vscode.
  den.aspects.cam.homeManager.programs.vscode.enable = true;
  den.aspects.cam.includes = [ (den._.unfree [ "vscode" ]) ];

  den.aspects.will.includes = [
    # will has always loved red snappers
    (den._.user-shell "fish")
    # will is primary user in WSL NixOS.
    den._.primary-user
  ];

  # Example: host provides parametric user configuration.
  den.aspects.rockhopper.includes = [
    host-to-user-conditional
  ];

  # Example: user provides parametric host configuration.
  den.aspects.alice.includes = [
    user-to-host-conditional
    # alice is always admin in all its hosts
    den._.primary-user
  ];

  # Example: standalone-hm config depends on osConfig (non-recursive)
  # NOTE: this will only work for standalone hm, and not for hosted hm
  # since a hosted hm configuration cannot depend on the os configuration.
  den.aspects.luke.includes = [
    os-conditional-hm
  ];

}
