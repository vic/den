{ den, withSystem, ... }:
{
  den.provides.inputs' = den.lib.parametric.exactly {
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

      **Note:** This aspect is contextual. When included in a `host` aspect, it
      configures `inputs'` for the host's OS. When included in a `user` or `home`
      aspect, it configures `inputs'` for the corresponding Home Manager configuration.
    '';

    includes = [
      (
        { OS, host }:
        let
          unused = den.lib.take.unused OS;
        in
        withSystem host.system (
          { inputs', ... }:
          {
            ${host.class}._module.args.inputs' = unused inputs';
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
          { inputs', ... }:
          {
            ${user.class}._module.args.inputs' = unused inputs';
          }
        )
      )
      (
        { HM, home }:
        let
          unused = den.lib.take.unused HM;
        in
        withSystem home.system (
          { inputs', ... }:
          {
            ${home.class}._module.args.inputs' = unused inputs';
          }
        )
      )
    ];
  };
}
