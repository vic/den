# An aspect that contributes to any user home on the bones hsot.
{ ... }:
let
  # private aspects can be let-bindings
  # more re-usable ones are better defined inside the `pro` namespace.
  host-contrib-to-user =
    { ... }: # replace with { user, host }:
    {
      homeManager = { };
    };
in
{
  den.aspects.bones._.common-user-env =
    { host, user }:
    {
      includes = map (f: f { inherit host user; }) [
        # add other aspects of yours that use host, user
        # to conditionally add behaviour.
        host-contrib-to-user
      ];
    };
}
