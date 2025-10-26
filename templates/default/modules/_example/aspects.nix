# example aspect dependencies for our hosts
# Feel free to remove it, adapt or split into modules.
{ inputs, ... }:
{

  flake.aspects =
    { aspects, ... }:
    {
      # rockhopper.nixos = { };  # config for rockhopper host
      # alice.homeManager = { }; # config for alice

      # wsl is an example aspect for github:nix-community/NixOS-WSL
      wsl.nixos = {
        imports = [ inputs.nixos-wsl.nixosModules.default ];
        wsl.enable = true;
      };

      # default.{host,user,home} can be used for global settings.
      default.host.darwin.system.stateVersion = 6;
      default.host.nixos =
        { modulesPath, ... }:
        {
          # for demo, we make all our nixos hosts vm bootable.
          imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
          system.stateVersion = "25.11";
        };

      default.home.homeManager =
        { lib, ... }:
        {
          home.stateVersion = lib.mkDefault "25.11";
        };

      # parametric host and user configs. see aspects-config.nix
      default.host.includes = [ aspects.example.provides.host ];
      default.user.includes = [ aspects.example.provides.user ];
      default.home.includes = [ aspects.example.provides.home ];

      # parametric providers.
      example.provides = {
        host =
          { host }:
          { class, ... }:
          {
            ${class}.networking.hostName = host.hostName;
          };

        user =
          { user, host }:
          let
            # different user configuration methods per OS
            darwin.system.primaryUser = user.userName;
            wsl.wsl.defaultUser = user.userName;
            nixos.users.users.${user.userName} = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };
          in
          _: {
            inherit darwin;
            # both regular nixos and nixos-on-wsl share the nixos class
            nixos = if host.aspect == "wsl" then wsl else nixos;
          };

        home =
          { home }:
          { class, ... }:
          {
            ${class}.home = {
              username = home.userName;
              homeDirectory = "/home/${home.userName}";
            };
          };
      };

    };

  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/nixos-wsl";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-compat.follows = "";
  };

}
