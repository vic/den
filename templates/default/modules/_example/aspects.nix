# example aspect dependencies for our hosts
# Feel free to remove it, adapt or split into modules.
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      # hosts
      rockhopper.includes = [ aspects.example.provides.host ];
      emperor.includes = [ aspects.example.provides.host ];

      # users
      alice.includes = [
        (aspects.example.provides.user "alice" "password")
      ];

      # aspects for demo purposes only.
      example.provides = {
        user = userName: insecurePassword: _: {
          nixos.users.users.${userName} = {
            password = insecurePassword;
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        };
        host = _: {
          nixos =
            { modulesPath, ... }:
            {
              imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
            };
        };
      };
    };
}
