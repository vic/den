{
  lib,
  den,
  inputs,
  ...
}:
let
  rawTypes = import ./types.nix { inherit den lib; };
  adapters = import ./adapters.nix { inherit den lib; };
  legacyResolve = import ./resolve.nix { inherit den lib; };
  hasAspect = import ./has-aspect.nix { inherit den lib; };
  fx = import ./fx { inherit den lib; };

  fxEnabled = den.fxPipeline or false;

  # When fxPipeline is enabled, resolve uses the fx effectful tree walk.
  # ctxApply has already been run (producing fixedTo/atLeast-wrapped aspects),
  # so we pass ctx = {} and let staticHandler handle class/aspect-chain.
  fxResolveTree =
    let
      nxFx =
        inputs.nix-effects.lib
          or (throw "den.fxPipeline requires nix-effects as a flake input. Add: inputs.nix-effects.url = \"github:vic/nix-effects\";");
      fxLib = fx.init nxFx;
    in
    class: resolved:
    let
      comp = fxLib.resolve.resolveDeepEffectful {
        ctx = { };
        inherit class;
        aspect-chain = [ ];
      } resolved;
      result = nxFx.handle {
        handlers = fxLib.resolve.defaultHandlers class;
        state = fxLib.resolve.defaultState;
      } comp;
    in
    {
      imports = result.state.imports;
    };

  resolve = if fxEnabled then fxResolveTree else legacyResolve;

  defaultFunctor = (den.lib.parametric { }).__functor;
  typesConf = { inherit defaultFunctor; };
  types = lib.mapAttrs (_: v: v typesConf) rawTypes;
in
{
  inherit
    types
    adapters
    resolve
    fx
    ;
  inherit (hasAspect) hasAspectIn collectPathSet mkEntityHasAspect;
  mkAspectsType = cnf': lib.mapAttrs (_: v: v (typesConf // cnf')) rawTypes;
}
