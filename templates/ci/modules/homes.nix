# Example standalone home-manager configurations.
# These are independent of any host configuration.
# See documentation at <den>/nix/types.nix
{ inputs, ... }:
{
  den.homes.x86_64-linux.cam = { };

  den.homes.aarch64-darwin.bob = {
    userName = "robert";
    aspect = "developer";
  };

  # Example: custom home-manager instantiate for passing extraSpecialArgs.
  den.homes.x86_64-linux.luke =
    let
      osConfig = inputs.self.nixosConfigurations.rockhopper.config;
    in
    {
      # Example: luke standalone-homemanager needs access to rockhopper osConfig.
      instantiate =
        { pkgs, modules }:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs modules;
          extraSpecialArgs.osConfig = osConfig;
        };

      # Example: custom attribute instead of specialArgs
      programToDependOn = "vim";
    };

}
