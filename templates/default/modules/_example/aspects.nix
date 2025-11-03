# example aspect dependencies for our hosts, checked at ci.nix
# Feel free to remove it, adapt or split into modules.
# see also: defaults.nix, compat-imports.nix, home-managed.nix
# see den provided aspects: <den>/modules/aspects/provides
{
  inputs,
  lib,
  den,
  ...
}:
let

  # Example: An aspect for vm installers.
  vm-bootable = {
    nixos =
      { modulesPath, ... }:
      {
        imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
      };
  };

  # Example: parametric host aspect to automatically set hostName on any host.
  set-host-name =
    { host }:
    {
      ${host.class}.networking.hostName = host.name;
    };

  # Example: alice enables programs on non-darwin
  host-conditional =
    { host, user }:
    if user.userName == "alice" && !lib.hasSuffix "darwin" host.system then
      {
        nixos.programs.tmux.enable = true;
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
  # Example: static aspects on host
  den.default.host.includes = [ vm-bootable ];

  # Example: parametric host aspects
  den.default.host._.host.includes = [ set-host-name ];

  # Example: parametric user aspect.
  den.default.user._.user.includes = [ den._.define-user ];

  # Example: parametric standalone-home aspect.
  den.default.home._.home.includes = [ den._.define-user._.home ];

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

  den.aspects.will._.user.includes = [
    # will has always loved red snappers
    (den._.user-shell "fish")
    # will is primary user in WSL NixOS.
    den._.primary-user
  ];

  # Example: user provides host configuration.
  den.aspects.alice._.user.includes = [
    host-conditional
    # alice is always admin in all its hosts
    den._.primary-user
  ];

  # Example: standalone-hm config depends on osConfig (non-recursive)
  # NOTE: this will only work for standalone hm, and not for hosted hm
  # since a hosted hm configuration cannot depend on the os configuration.
  den.aspects.luke._.home.includes = [
    os-conditional-hm
  ];

}
