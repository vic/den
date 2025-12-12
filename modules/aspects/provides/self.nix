{ den, withSystem, ... }:
{
  den.provides.self' = den.lib.parametric {
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

      **Note:** If specified in a user aspect (e.g., `alice`) that is integrated into a host (not standalone),
      `self'` will be available to **both** the user's Home Manager configuration and the **Host's** configuration.
    '';

    includes = [
      (
        { host, user, ... }:
        (withSystem host.system (
          { self', ... }:
          {
            ${host.class}._module.args.self' = self';
            ${user.class or null}._module.args.self' = self';
          }
        ))
      )
      (
        { home, ... }:
        (withSystem home.system (
          { self', ... }:
          {
            ${home.class}._module.args.self' = self';
          }
        ))
      )
    ];
  };
}
