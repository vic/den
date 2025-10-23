# example aspect dependencies for our hosts
# Feel free to remove it, adapt or split into modules.
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      # hosts
      # rockhopper.nixos = { }; # config for rockhopper host

      # on all hosts. see aspects-config.nix
      defaults.host.includes = [ aspects.example.provides.host ];

      # users
      # alice.homeManager = { }; # config for alice

      # on all users. see aspects-config.nix
      defaults.user.includes = [ aspects.example.provides.user ];

      # parametric providers.
      example.provides = {
        host = host: _: {
          nixos =
            { modulesPath, ... }:
            {
              imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
              networking.hostName = host.hostName;
            };
        };

        user = _host: user: _: {
          nixos.users.users.${user.userName} = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        };
      };
    };
}
