let

  # Example: adds hello into each user. provides only to OS.
  hello-package-for-user =
    {
      user,
      host,
      ...
    }:
    {
      ${host.class} =
        { pkgs, ... }:
        {
          users.users.${user.userName}.packages = [ pkgs.hello ];
        };
    };

in
{

  den.default.includes = [ hello-package-for-user ];

  perSystem =
    {
      checkCond,
      rockhopper,
      lib,
      ...
    }:
    {
      checks.alice-hello-enabled-by-default = checkCond "added hello at user packages" (
        let
          progs = rockhopper.config.users.users.alice.packages;
          expr = map lib.getName progs;
          expected = [ "hello" ];
        in
        expr == expected
      );
    };

}
