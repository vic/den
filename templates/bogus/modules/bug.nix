{ denTest, ... }:
{
  flake.tests.bogus = {

    test-something = denTest (
      {
        den,
        lib,
        # igloo, # igloo = nixosConfigurations.igloo.config
        apple,
        tuxHm, # tuxHm = igloo.home-manager.users.tux
        ...
      }:
      {
        den.hosts.aarch64-darwin.apple.users.tux = { };

        # do something for testing
        den.aspects.tux.user.description = "The Penguin";

        expr = apple.users.users.tux.description;
        expected = "The Penguin";
      }
    );

  };
}
