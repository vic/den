{ den, lib, ... }:
let
  inherit (den.lib) parametric;

  description = ''
    Provides a forward battery that allows you to quickly generate custom
    classes for flake parts `perSystem` outputs.

    This is useful for integrating with other popular flake parts libraries,
    such as terranix, devshell, files, etc.

    ## Usage

        den.default.includes = [ den._.per-system ];

    **Note:** This aspect does not create any custom classes for you. Please
    see other flake-parts batteries or the `flake-parts` template to learn how
    to create custom classes.
  '';

  perSystemFwd =
    forwardArgs:
    { class, aspect-chain }:
    den._.forward (
      {
        each = lib.optional (class == "flake-parts") forwardArgs;
        intoClass = _: "flake-parts";
        fromAspect = _: lib.head aspect-chain;
        adaptArgs = { config, ... }: config.allModuleArgs;
      }
      // forwardArgs
      // lib.optionalAttrs (!forwardArgs ? intoPath) {
        intoPath = x: [ (forwardArgs.fromClass x) ];
      }
    );

  ctx.flake-parts = { };
  ctx.flake-parts-system.provides.flake-parts-system = perSystemFwd;
  perSystemModule = den.lib.aspects.resolve "flake-parts" (den.ctx.flake-parts { });
in
{
  den.provides.classes-per-system = parametric.exactly {
    inherit description;
    den.ctx = ctx;
    perSystem.imports = [ perSystemModule ];
  };
}
