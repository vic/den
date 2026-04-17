{ den, ... }:
let
  inherit (den.lib) parametric;

  description = ''
    Projects all homeManager-class configs from the host's aspect tree
    onto users who opt in. Requires the fx pipeline.

    ## Usage

      den.aspects.tux.includes = [ den._.host-aspects ];

    Any host aspect that defines a `homeManager` key will have that
    config forwarded to the user's homeManager evaluation. Other class
    keys (nixos, darwin) are ignored — host.aspect is resolved
    specifically for class "homeManager".
  '';

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
