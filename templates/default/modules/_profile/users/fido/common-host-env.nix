# An aspect that contributes to any operating system where fido is a user.
# hooks itself into any host.
{ pro, ... }:
let
  fido-at-host =
    { fromUser, toHost }: if fromUser.name != "fido" then { } else pro.fido._.${toHost.name};
in
{
  den.default.includes = [
    fido-at-host
  ];

  # fido on bones host.
  pro.fido._.bones.nixos = { };
}
