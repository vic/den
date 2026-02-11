{ den, inputs, ... }:
{
  # The `{ HM-OS-HOST }` context is activated ONLY for hosts that have
  # a HM supported OS and at least one user with homeManager class.
  den.aspects.hm-global-pkgs =
    { HM-OS-HOST }:
    {
      nixos.home-manager.useGlobalPkgs = HM-OS-HOST.host.hostName == "rockhopper";
    };

  den.aspects.rockhopper.includes = [ den.aspects.hm-global-pkgs ];

  den.hosts.x86_64-linux.no-homes = { };

  perSystem =
    { checkCond, rockhopper, ... }:
    {
      checks.rockhopper-hm-global-pkgs = checkCond "rockhopper-hm-global-pkgs" (
        rockhopper.config.home-manager.useGlobalPkgs
      );

      checks.no-homes-hm-global-pkgs = checkCond "no-homes-hm-global-pkgs" (
        # no home-manager enabled nor useGlobalPkgs
        !inputs.self.nixosConfigurations.no-homes.config ? home-manager.useGlobalPkgs
      );
    };

}
