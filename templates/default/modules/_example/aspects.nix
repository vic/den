# example aspect dependencies for our hosts
# Feel free to remove it, adapt or split into modules.
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      # hosts
      # rockhopper.nixos = { }; # config for rockhopper host

      # parametric host configs. see aspects-config.nix
      default.host.includes = [ aspects.example.provides.host ];
      # host defaults.
      default.host.darwin.system.stateVersion = 6;
      # for demo, we make all our nixos hosts vm bootable.
      default.host.nixos =
        { modulesPath, ... }:
        {
          system.stateVersion = "25.11";
          imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
        };

      # users
      # alice.homeManager = { }; # config for alice

      # parametric default user configs. see aspects-config.nix
      default.user.includes = [ aspects.example.provides.user ];

      # parametric providers.
      example.provides = {
        host =
          host:
          { class, ... }:
          {
            ${class}.networking.hostName = host.hostName;
          };

        user = _host: user: _: {
          darwin.system.principalUser = user.userName;
          nixos.users.users.${user.userName} = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        };
      };
    };
}
