# Adds some checks for CI
{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      checkFile =
        file:
        pkgs.runCommandLocal "check-file-exists" { } ''
          ls -la ${file} | tee $out
        '';

      checks.x86_64-linux = {
        vm = checkFile "${self.nixosConfigurations.rockhopper.config.system.build.vm}/bin/run-rockhopper-vm";
        hosts-adelie = checkFile self.wslConfigurations.adelie.config.system.build.toplevel;
        homes-alice = checkFile self.homeConfigurations.alice.activation-script;
      };

      checks.aarch64-darwin = {
        hosts-honeyscrisp = checkFile self.darwinConfigurations.honeycrisp.config.system.build.toplevel;
        homes-bob = checkFile self.homeConfigurations.bob.activation-script;
      };
    in
    {
      checks = checks.${pkgs.system} or { };
    };
}
