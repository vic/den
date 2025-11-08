# An aspect that contributes to any operating system where fido is a user.
# hooks itself into any host.
{ pro, ... }:
let
  fido-at-host =
    { userToHost, ... }:
    if userToHost.user.name != "fido" then { } else pro.fido._.${userToHost.host.name};
in
{
  den.default.includes = [
    fido-at-host
  ];

  # fido on bones host.
  pro.fido._.bones.nixos = { };
}
