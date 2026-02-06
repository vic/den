{
  den.default.includes =
    let
      # Example: parametric host aspect to automatically set hostName on any host.
      set-host-name =
        { host, ... }:
        {
          ${host.class}.networking.hostName = host.name;
        };
    in
    [ set-host-name ];

  perSystem =
    {
      checkCond,
      rockhopper,
      honeycrisp,
      ...
    }:
    {
      checks.rockhopper-hostname = checkCond "den.default.host.includes sets hostName" (
        rockhopper.config.networking.hostName == "rockhopper"
      );

      checks.honeycrisp-hostname = checkCond "den.default.host.includes sets hostName" (
        honeycrisp.config.networking.hostName == "honeycrisp"
      );
    };
}
