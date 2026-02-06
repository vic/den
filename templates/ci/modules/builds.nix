# Adds some checks for CI
{
  perSystem =
    {
      pkgs,
      checkFile,
      rockhopper,
      honeycrisp,
      cam,
      bob,
      ...
    }:
    let
      checks.x86_64-linux = {
        vm = checkFile "vm-builds" "${rockhopper.config.system.build.vm}/bin/run-rockhopper-vm";
        hosts-rockhopper = checkFile "nixos-builds" rockhopper.config.system.build.toplevel;
        homes-cam = checkFile "home-builds" cam.activation-script;
      };
      checks.aarch64-darwin = {
        hosts-honeycrisp = checkFile "darwin-builds" honeycrisp.config.system.build.toplevel;
        homes-bob = checkFile "darwin-home-builds" bob.activation-script;
      };
    in
    {
      checks = checks.${pkgs.stdenv.hostPlatform.system} or { };
    };
}
