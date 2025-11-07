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

  userToHostContext =
    { fromUser, toHost }:
    let
      on-wsl.nixos.wsl.defaultUser = fromUser.userName;
    in
    {
      inherit description;
      includes = lib.optionals (toHost ? wsl) [ on-wsl ];
      darwin.system.primaryUser = fromUser.userName;
      nixos.users.users.${fromUser.userName} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };
    };

in
{
  den.provides.primary-user = userToHostContext;
}
