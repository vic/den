{
  den._.user-shell = {
    description = ''
      Sets a user default shell, enables the shell at OS and home level.

      Usage:

        den.aspects.my-user._.user.includes = [
          (den._.user-shell { shell = "fish"; })
        ];
    '';

    __functor =
      _:
      shell:
      { user, ... }:
      # deadnix: skip
      { class, ... }:
      {
        homeManager.programs.${shell}.enable = true;
        # Help needed: how to set default shell in darwin?
        nixos =
          { pkgs, ... }:
          {
            programs.${shell}.enable = true;
            users.users.${user.userName}.shell = pkgs.${shell};
          };
      };
  };
}
