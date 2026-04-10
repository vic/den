{ denTest, ... }:
{
  flake.tests.deadbugs-issue-429 = {

    test-parametrized-aspect = denTest (
      {
        den,
        igloo,
        ...
      }:
      {
        den.ctx.user.includes = [ den._.mutual-provider ];
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.provides.to-users = {
          includes = [ (den.aspects.base-user "DESCRIPTION") ];
        };

        den.aspects.base-user = description: 
          { user.description = description; };

        expr = igloo.users.users.tux.description;
        expected = "DESCRIPTION";
      }
    );

  };
}
