{ den, withSystem, ... }:
{
  den.provides.self' = den.lib.parametric {
    description = ''
      Provides the `flake-parts` `self'` (the flake's `self` with system pre-selected)
      as a top-level module argument. This allows modules to access per-system
      flake outputs without needing `pkgs.stdenv.hostPlatform.system`.

      ## Usage

          # makes self' available to modules in my-aspect
          den.aspects.my-aspect.includes = [ den._.self' ];

          # module implementation
          { self', ... }: { 
            # use self' as needed
          }
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
