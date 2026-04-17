{ den, ... }:
let
  inherit (den.lib) parametric;

  description = ''
    Projects all homeManager-class configs from the host's aspect tree
    onto users who opt in.

    ## Usage

      den.aspects.tux.includes = [ den._.host-aspects ];

    Any host aspect that defines a `homeManager` key will have that
    config forwarded to the user's homeManager evaluation. Other class
    keys (nixos, darwin) are ignored — host.aspect is resolved
    specifically for class "homeManager", so only homeManager modules
    are collected. This avoids duplicating nixos modules that are
    already applied via the host's own resolution.
  '';

  # Resolve host.aspect for homeManager class only, producing a single
  # homeManager module. This prevents nixos/darwin class keys from
  # being collected again when the user context contributes to the
  # host's resolution.
  from-host =
    { host, user }:
    {
      homeManager = den.lib.aspects.resolve "homeManager" (
        parametric.fixedTo { inherit host user; } host.aspect
      );
    };

in
{
  den.provides.host-aspects = parametric.exactly {
    inherit description;
    includes = [ from-host ];
  };
}
