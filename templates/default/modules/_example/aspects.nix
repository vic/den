# example aspect dependencies for our hosts, checked at ci.nix
# Feel free to remove it, adapt or split into modules.
# see also: defaults.nix, compat-imports.nix, home-managed.nix
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

  homeDir =
    userName: system:
    if lib.hasSuffix "darwin" system then "/Users/${userName}" else "/home/${userName}";

  set-home-dir = userName: system: {
    homeManager.home.username = userName;
    homeManager.home.homeDirectory = homeDir userName system;
  };

  # Example: parametric user aspect to define os-level user.
  define-user =
    { host, user }:
    {
      nixos.users.users.${user.name}.isNormalUser = true;
      darwin.users.users.${user.name} = {
        name = user.userName;
        home = homeDir user.userName host.system;
      };
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

in
{
  # Example: static aspects on host
  den.default.host.includes = [ vm-bootable ];

  # Example: parametric host aspects
  den.default.host._.host.includes = [ set-host-name ];

  # Example: parametric user aspect.
  den.default.user._.user.includes = [
    define-user
    ({ host, user }: set-home-dir user.userName host.system)
  ];

  # Example: parametric home aspect.
  den.default.home._.home.includes = [
    ({ home }: set-home-dir home.userName home.system)
  ];

  # Example: adelie host using github:nix-community/NixOS-WSL
  den.aspects.adelie.nixos = {
    imports = [ inputs.nixos-wsl.nixosModules.default ];
    wsl.enable = true;
  };

  # Example: enable helix for alice on all its home-managed hosts.
  den.aspects.alice.homeManager.programs.helix.enable = true;

  # can uses unfree vscode.
  den.aspects.cam.homeManager.programs.vscode.enable = true;
  den.aspects.cam.includes = [ (den._.unfree { allow = [ "vscode" ]; }) ];

  den.aspects.will._.user.includes = [
    # will has always loved red snappers
    (den._.user-shell { shell = "fish"; })
    # will is primary user in WSL NixOS.
    den._.primary-user
  ];

  # Example: user provides host configuration.
  den.aspects.alice._.user.includes = [
    host-conditional
    # alice is always admin in all its hosts
    den._.primary-user
  ];

}
