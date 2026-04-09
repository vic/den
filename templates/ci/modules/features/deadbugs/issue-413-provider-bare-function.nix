# Provider sub-aspect as bare function with host context.
# https://github.com/vic/den/pull/413
{ denTest, lib, ... }:
{
  flake.tests.deadbugs-issue-413 = {
    test-provider-sub-aspect-bare-function = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        imports =
          let
            a = {
              den.aspects.foo =
                { host, ... }:
                {
                  includes = lib.optionals (host.foo._.sub.enable == true) [
                    den.aspects.foo._.sub
                  ];
                };
            };
            b = {
              den.schema.host.options.foo._.sub.enable = lib.mkEnableOption "sub-aspect toggle";
            };
            c = {
              den.hosts.x86_64-linux.igloo.foo._.sub.enable = true;
            };
            d = {
              den.aspects.foo._.sub =
                { host, ... }:
                {
                  nixos = lib.optionalAttrs (host.hostName != "whatever") {
                    networking.networkmanager.enable = true;
                  };
                };
            };
          in
          [
            a
            b
            c
            d
          ];

        den.aspects.igloo.includes = [ den.aspects.foo ];

        expr = igloo.networking.networkmanager.enable;
        expected = true;
      }
    );
  };
}
