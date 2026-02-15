{ denTest, ... }:
{
  flake.tests.os-user = {

    test-forwards-user-description = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.tux.user.description = "pinguino";

        expr = igloo.users.users.tux.description;
        expected = "pinguino";
      }
    );

  };
}
