{ denTest, ... }:
{

  flake.tests.primary-user.test-on-nixos-included-at-user = denTest (
    {
      den,
      lib,
      igloo,
      ...
    }:
    {
      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.aspects.tux.includes = [ den._.primary-user ];
      expr = igloo.users.users.tux.extraGroups;
      expected = [
        "wheel"
        "networkmanager"
      ];
    }
  );

}
