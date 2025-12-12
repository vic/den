{ den, withSystem, ... }:
{
  den.provides.inputs' = den.lib.parametric {
    description = ''
      Provides the `flake-parts` `inputs'` (the flake's `inputs` with system pre-selected)
      as a top-level module argument. This allows modules to access per-system
      flake outputs without needing `pkgs.stdenv.hostPlatform.system`.

      ## Usage

          # makes inputs' available to modules in my-aspect
          den.aspects.my-aspect.includes = [ den._.inputs' ];

          # module implementation
          { inputs', ... }: {
            # use inputs' as needed
          }
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
