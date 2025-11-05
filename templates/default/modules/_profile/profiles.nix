# Profiles are just aspects whose only job is to include other aspects
# based on the properties (context) of the host/user they are included in.
{ pro, den, ... }:
{

  # install profiles as parametric aspects on all hosts/users
  den.default.includes = [
    pro.profiles
  ];

  pro.profiles = {
    __functor = den.lib.parametric true;
    includes = [
      ({ host }: pro.${host.system} or { })
      # add other routes according to context.
    ];
  };

}
