{ lib, ... }:
let
  description = ''
    Sets user as *primary*.

    On NixOS adds wheel and networkmanager groups.
    On Darwin sets user as system.primaryUser
    On WSL sets wsl.defaultUser if host has an `wsl` attribute.

    ## Usage

       den.aspects.my-user.includes = [ den._.primary-user ];

  '';

  osConfig =
    { user, host }:
    let
      on-wsl.nixos.wsl.defaultUser = user.userName;
    in
    {
      includes = lib.optionals (host ? wsl) [ on-wsl ];
      darwin.system.primaryUser = user.userName;
      nixos.users.users.${user.userName} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };
    };

in
{
  den.provides.primary-user = {
    inherit description;
    __functor = _self: osConfig;
  };
}
