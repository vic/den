{ den, ... }:
let

  description = ''
    Sets a user default shell, enables the shell at OS and Home level.

    Usage:

      den.aspects.vic.includes = [
        # will always love red snappers.
        (den._.user-shell "fish")
      ];
  '';

  userContext =
    { shell }:
    { host }:
    {
      homeManager.programs.${shell}.enable = true;
    };

  userToHostContext =
    { shell }:
    { fromUser, toHost }:
    let
      nixos =
        { pkgs, ... }:
        {
          programs.${shell}.enable = true;
          users.users.${fromUser.userName}.shell = pkgs.${shell};
        };
      darwin = nixos;
    in
    {
      inherit nixos darwin;
    };

in
{
  den.provides.user-shell = shell: {
    inherit description;
    __functor = den.lib.parametric true;
    includes = map (f: f { inherit shell; }) [
      userContext
      userToHostContext
    ];
  };
}
