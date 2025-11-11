# An aspect that contributes to any user home on the bones host.
{ ... }:
let
  # private aspects can be let-bindings
  # more re-usable ones are better defined inside the `pro` namespace.
  host-contrib-to-user =
    { hostToUser, ... }:
    if hostToUser.host.name == "bones" || hostToUser.user.name == "fido" then
      {
        homeManager.programs.vim.enable = true;
      }
    else
      { };
in
{
  den.default.includes = [
    host-contrib-to-user
  ];
}
