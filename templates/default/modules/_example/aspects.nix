# example aspect dependencies for our hosts, checked at ci.nix
# Feel free to remove it, adapt or split into modules.
# see also: defaults.nix, compat-imports.nix, home-managed.nix
{
  inputs,
  lib,
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
    let
      on-linux.nixos.users.users.${user.name}.isNormalUser = true;
      on-macos.darwin.users.users.${user.name} = {
        name = user.userName;
        home = homeDir user.userName host.system;
      };

      macos-admin.darwin.system.primaryUser = user.name;
      wsl-admin.nixos.wsl.defaultUser = user.name;

      per-host = { adelie = wsl-admin; }.${host.name} or { };

      aspect.includes = [
        on-macos
        on-linux
        macos-admin
        per-host
      ];
    in
    aspect;

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

  # Example: user provides host configuration.
  den.aspects.alice._.user.includes = [ host-conditional ];

}
