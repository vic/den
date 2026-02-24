{ denTest, ... }:
{
  flake.tests.bogus = {

    test-something = denTest (
      {
        den,
        lib,
        igloo, # igloo = nixosConfigurations.igloo.config
        tuxHm, # tuxHm = igloo.home-manager.users.tux
        ...
      }:
      {
        # replace <system> if you are reporting a bug in MacOS
        den.hosts.x86_64-linux.igloo.users.tux = { };

        # do something for testing
        den.aspects.tux.user.description = "The Penguin";

        expr = igloo.users.users.tux.description;
        expected = "The Penguin";
      }
    );

  };
}
