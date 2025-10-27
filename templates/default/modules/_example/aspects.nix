# example aspect dependencies for our hosts
# Feel free to remove it, adapt or split into modules.
{ inputs, lib, ... }:
{

  flake.aspects =
    { aspects, ... }:
    {
      # rockhopper.nixos = { };  # config for rockhopper host
      # alice.homeManager = { }; # config for alice
      developer = {
        description = "aspect for bob's standalone home-manager";
        homeManager = { };
      };

      # aspect for adelie host using github:nix-community/NixOS-WSL
      wsl.nixos = {
        imports = [ inputs.nixos-wsl.nixosModules.default ];
        wsl.enable = true;
      };

      # default.{host,user,home} can be used for global settings.
      default.host.darwin.system.stateVersion = lib.mkDefault 6;
      default.host.nixos.system.stateVersion = "25.11";
      default.home.homeManager.home.stateVersion = lib.mkDefault "25.11";

      # parametric host and user default configs. see aspects-config.nix
      default.host.includes = [ aspects.example.provides.host ];
      default.user.includes = [ aspects.example.provides.user ];
      default.home.includes = [ aspects.example.provides.home ];

      # aspect for each host that includes the user alice.
      alice.provides.hostUser =
        { user, ... }:
        {
          # administrator in all nixos hosts
          nixos.users.users.${user.userName} = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        };

      # subtree of aspects for demo purposes.
      example.provides = {

        # in our example, we allow all nixos hosts to be vm-bootable.
        vm-bootable = {
          nixos =
            { modulesPath, ... }:
            {
              imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
            };
        };

        # parametric providers.
        host =
          { host }:
          { class, ... }:
          {
            includes = [ aspects.example.provides.vm-bootable ];
            ${class}.networking.hostName = host.hostName;
          };

        user =
          { user, host }:
          let
            aspect = {
              name = "(example.user ${host.name} ${user.name})";
              description = "user setup on different OS";
              darwin.system.primaryUser = user.userName;
              nixos.users.users.${user.userName}.isNormalUser = true;
            };

            # adelie is nixos-on-wsl, has special user setup
            by-host.adelie = {
              nixos.defaultUser = user.userName;
            };
          in
          by-host.${host.name} or aspect;

        home =
          { home }:
          { class, ... }:
          let
            path = if lib.hasSuffix "darwin" home.system then "/Users" else "/home";
          in
          {
            ${class}.home = {
              username = home.userName;
              homeDirectory = "${path}/${home.userName}";
            };
          };

      };

    };
}
