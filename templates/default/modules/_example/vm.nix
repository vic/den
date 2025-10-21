{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {

      # Use `nix run .` to run the rockhopper vm.
      packages.default = pkgs.writeShellApplication {
        name = "vm";
        text = ''
          ${inputs.self.nixosConfigurations.rockhopper.config.system.build.vm}/bin/run-nixos-vm "$@"
        '';
      };

    };
}
