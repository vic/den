{ den, withSystem, ... }:
{
  den.provides.self' = den.lib.parametric.exactly {
    description = ''
      Provides the `flake-parts` `self'` (the flake's `self` with system pre-selected)
      as a top-level module argument.

      This allows modules to access per-system flake outputs without needing
      `pkgs.stdenv.hostPlatform.system`.

      ## Usage

      **Global (Recommended):**
      Apply to all hosts, users, and homes.

          den.default.includes = [ den._.self' ];

      **Specific:**
      Apply only to a specific host, user, or home aspect.

          den.aspects.my-laptop.includes = [ den._.self' ];
          den.aspects.alice.includes = [ den._.self' ];

      **Note:** This aspect is contextual. When included in a `host` aspect, it
      configures `self'` for the host's OS. When included in a `user` or `home`
      aspect, it configures `self'` for the corresponding Home Manager configuration.
    '';

    includes = [
      (
        { OS, host }:
        let
          unused = den.lib.take.unused OS;
        in
        withSystem host.system (
          { self', ... }:
          {
            ${host.class}._module.args.self' = unused self';
          }
        )
      )
      (
        {
          OS,
          HM,
          user,
          host,
        }:
        let
          unused = den.lib.take.unused [
            OS
            HM
          ];
        in
        withSystem host.system (
          { self', ... }:
          {
            ${user.class}._module.args.self' = unused self';
          }
        )
      )
      (
        { HM, home }:
        let
          unused = den.lib.take.unused HM;
        in
        withSystem home.system (
          { self', ... }:
          {
            ${home.class}._module.args.self' = unused self';
          }
        )
      )
    ];
  };
}
