# An aspect that contributes to any operating system where fido is a user.
{ ... }:
let
  # private aspects can be in variables
  # more re-usable ones are better defined inside the `pro` namespace.
  user-contrib-to-host =
    # { user, host }: # uncomment if needed
    {
      nixos = { };
      darwin = { };
    };
in
{
  den.aspects.fido.provides.host.includes = [
    # add other aspects of yours that use host, user
    # to conditionally add behaviour.
    user-contrib-to-host
  ];
}
