{
  den.provides.user-shell = {
    description = ''
      Sets a user default shell, enables the shell at OS and Home level.

      Usage:

        den.aspects.vic.includes = [
          # will always love red snappers.
          (den._.user-shell "fish")
        ];
    '';

    __functor =
      _: shell:
      # deadnix: skip
      { user, host }:
      let
        homeManager.programs.${shell}.enable = true;
        nixos =
          { pkgs, ... }:
          {
            programs.${shell}.enable = true;
            users.users.${user.userName}.shell = pkgs.${shell};
          };
        darwin = nixos;
      in
      {
        inherit nixos darwin homeManager;
      };
  };
}
