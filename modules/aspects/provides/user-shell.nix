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

  userShell =
    shell: user:
    let
      nixos =
        { pkgs, ... }:
        {
          programs.${shell}.enable = true;
          users.users.${user.userName}.shell = pkgs.${shell};
        };
      darwin = nixos;
      homeManager.programs.${shell}.enable = true;
    in
    {
      inherit nixos darwin homeManager;
    };

in
{
  den.provides.user-shell =
    shell:
    den.lib.parametric {
      inherit description;
      includes = [
        ({ user, ... }: userShell shell user)
        ({ home, ... }: userShell shell home)
      ];
    };
}
