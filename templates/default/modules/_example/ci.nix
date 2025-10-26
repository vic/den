# Adds some checks for CI
{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      # our CI only has linux enabled for now. TODO: add mac runners.
      checks = if pkgs.system == "x86_64-linux" then linux else { };

      mkCheck = name: checkPhase: pkgs.runCommandLocal name { } checkPhase;

      linux = {
        vm = mkCheck "vm" ''
          ls -la ${self.nixosConfigurations.rockhopper.config.system.build.vm}/bin/run-rockhopper-vm | tee $out
        '';

        homes-alice = mkCheck "homes-alice" ''
          ls -la ${self.homeConfigurations.alice.activation-script} | tee $out
        '';
      };
    in
    {
      inherit checks;
    };
}
