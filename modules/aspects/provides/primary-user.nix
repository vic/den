{ lib, ... }:
{
  den._.primary-user.description = ''
    Sets user as "primary".

    On NixOS it adds whell group.
    On Darwin it sets system.primaryUser
    For WSL sets wsl.defaultUser if host has an `wsl` attribute.

    ## Usage

       den.aspects.my-user._.user.includes = [ 
         (den._.primary-user)
       ];
  '';
  den._.primary-user.__functor =
    _:
    { user, host }:
    # deadnix: skip
    { class, ... }:
    let
      on-wsl.nixos.wsl.defaultUser = user.userName;
    in
    {
      includes = lib.optionals (host ? wsl) [ on-wsl ];
      darwin.system.primaryUser = user.userName;
      nixos = {
        users.users.${user.userName} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
      };
    };
}
