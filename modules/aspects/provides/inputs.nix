{ den, withSystem, ... }:
{
  den.provides.inputs' = den.lib.parametric {
    description = ''
      Provides the `flake-parts` `inputs'` (the flake's `inputs` with system pre-selected)
      as a top-level module argument.

      This allows modules to access per-system flake outputs without needing
      `pkgs.stdenv.hostPlatform.system`.

      ## Usage

      **Global (Recommended):**
      Apply to all hosts, users, and homes.

          den.default.includes = [ den._.inputs' ];

      **Specific:**
      Apply only to a specific host, user, or home aspect.

          den.aspects.my-laptop.includes = [ den._.inputs' ];
          den.aspects.alice.includes = [ den._.inputs' ];

      **Note:** If specified in a user aspect (e.g., `alice`) that is integrated into a host (not standalone),
      `inputs'` will be available to **both** the user's Home Manager configuration and the **Host's** configuration.
    '';

    includes = [
      (
        { host, user, ... }:
        (withSystem host.system (
          { inputs', ... }:
          {
            ${host.class}._module.args.inputs' = inputs';
            ${user.class or null}._module.args.inputs' = inputs';
          }
        ))
      )
      (
        { home, ... }:
        (withSystem home.system (
          { inputs', ... }:
          {
            ${home.class}._module.args.inputs' = inputs';
          }
        ))
      )
    ];
  };
}
