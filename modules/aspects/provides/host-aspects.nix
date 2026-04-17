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
    keys (nixos, darwin) are ignored — the pipeline resolves with
    class = "homeManager" so only homeManager modules are collected.
  '';

  from-host = { host, user }: parametric.fixedTo { inherit host user; } host.aspect;

in
{
  den.provides.host-aspects = parametric.exactly {
    inherit description;
    includes = [ from-host ];
  };
}
