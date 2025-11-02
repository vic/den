# An aspect that contributes to any operating system where fido is a user.
{ ... }:
let
  # private aspects can be in variables
  # more re-usable ones are better defined inside the `pro` namespace.
  user-contrib-to-host =
    { ... }: # replace with: { user, host }:
    {
      nixos = { };
      darwin = { };
    };
in
{
  den.aspects.fido._.common-host-env =
    { host, user }:
    {
      includes = map (f: f { inherit host user; }) [
        # add other aspects of yours that use host, user
        # to conditionally add behaviour.
        user-contrib-to-host
      ];
    };
}
