# Tests for den's wrapAspect — the aspect → computation translation.
# Tests verify den's wrapper behavior, not the nix-effects API.
{
  denTest,
  inputs,
  lib,
  ...
}:
let
  fx = inputs.nix-effects.lib;
in
{
  flake.tests.fx-aspect = {

    # wrapAspect dispatches normal aspects through bind.fn.
    test-wrapAspect-normal = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ctx = {
          host = "igloo";
        };
        aspect =
          { host }:
          {
            hostName = host;
          };
        comp = fxLib.wrapAspect ctx aspect;
        result = fx.handle {
          handlers.host =
            { param, state }:
            {
              resume = "igloo";
              inherit state;
            };
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          hostName = "igloo";
        };
      }
    );

    # wrapAspect wraps static attrsets in fx.pure.
    test-wrapAspect-static = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        comp = fxLib.wrapAspect { } { enable = true; };
        result = fx.handle {
          handlers = { };
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          enable = true;
        };
      }
    );

    # wrapAspect passes full context to factory functions (empty functionArgs).
    test-wrapAspect-factory = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        factory = ctx: { got = ctx.host; };
        comp = fxLib.wrapAspect { host = "igloo"; } factory;
        result = fx.handle {
          handlers = { };
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          got = "igloo";
        };
      }
    );

  };
}
