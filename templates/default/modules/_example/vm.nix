{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text = ''
          ${inputs.self.nixosConfigurations.rockhopper.config.system.build.vm}/bin/run-rockhopper-vm "$@"
        '';
      };
    };
}
