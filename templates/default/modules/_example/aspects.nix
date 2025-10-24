# example aspect dependencies for our hosts
# Feel free to remove it, adapt or split into modules.
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      # rockhopper.nixos = { };  # config for rockhopper host
      # alice.homeManager = { }; # config for alice

      # default.{host,user} can be used for global settings.
      default.host.darwin.system.stateVersion = 6;
      default.host.nixos =
        { modulesPath, ... }:
        {
          # for demo, we make all our nixos hosts vm bootable.
          imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
          system.stateVersion = "25.11";
        };

      # parametric host and user configs. see aspects-config.nix
      default.host.includes = [ aspects.example.provides.host ];
      default.user.includes = [ aspects.example.provides.user ];

      # parametric providers.
      example.provides = {
        host =
          { host }:
          { class, ... }:
          {
            ${class}.networking.hostName = host.hostName;
          };

        user =
          { user, ... }:
          _: {
            darwin.system.principalUser = user.userName;
            nixos.users.users.${user.userName} = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };
          };
      };
    };
}
