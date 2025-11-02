# Profiles are just aspects whose only job is to include other aspects
# based on the properties (context) of the host/user they are included in.
{ den, pro, ... }:
{

  # install profiles as parametric aspects on all hosts/users
  den.default.host._.host.includes = [ pro.by-host ];
  den.default.user._.user.includes = [ pro.by-user ];

  # `by-host { host }`
  #
  # den automatically includes `den.aspects.${host.name}`, besides that
  # this profile adds the following aspects if they exist:
  #
  # - `den.aspects.profile._.${system}` eg, an aspect per host hardware platform.
  #
  # since the `host` type is a freeform (see types.nix) you can add
  # custom attributes to your hosts and use them to dispatch for
  # common aspects. eg, by host network, etc.
  #
  # Also, remember that aspects can form a tree structure by using their
  # `provides` attribute, not all aspects need to exist at same level.
  pro.by-host =
    { host }:
    {
      includes = [
        (pro.${host.system} or { })
      ];
    };

  # `by-user { host, user }`
  #
  # den automatically includes `den.aspects.${user.name}`.
  # a user can contribute modules to the host is part of, and also
  # define its own home-level configs.
  #
  # this profile adds the following aspects if they exist:
  #
  #  - `den.aspects.<host>._.common-user-env { host, user }`: included on each user of a host.
  #  - `den.aspects.<user>._.common-host-env { host, user }`: included on each host where a user exists.
  #
  #  - `den.aspects.profile._.single-user-is-admin { host, user }`
  #
  # Since both host and user types are freeforms, you might add custom attributes
  # to them and your parametric aspects can use those attributes to conditionally add
  # features into the host or user level.
  pro.by-user =
    { host, user }:
    {
      includes =
        let
          noop = _: { };
          apply = f: f { inherit host user; };
        in
        map apply [
          (den.aspects.${host.name}._.common-user-env or noop)
          (den.aspects.${user.name}._.common-host-env or noop)

          pro.single-user-is-admin
        ];
    };

}
