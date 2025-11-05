# An aspect that contributes to any user home on the bones host.
{ ... }:
let
  # private aspects can be let-bindings
  # more re-usable ones are better defined inside the `pro` namespace.
  host-contrib-to-user =
    # { host, user }: # uncomment if needed
    {
      homeManager.programs.vim.enable = true;
    };
in
{
  den.aspects.bones.provides.user.includes = [
    # add other aspects of yours that use host, user
    # to conditionally add behaviour.
    host-contrib-to-user
  ];
}
