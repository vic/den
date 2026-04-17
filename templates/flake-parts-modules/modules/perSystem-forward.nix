{ den, lib, ... }:
let

  perSystemFwd =
    forwardArgs:
    { class, ... }:
    den.provides.forward (
      {
        each = lib.optional (class == "flake-parts") forwardArgs;
        intoClass = _: "flake-parts";
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
  den.ctx = ctx;
  perSystem.imports = [ perSystemModule ];
}
