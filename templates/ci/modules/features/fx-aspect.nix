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

    # bind.fn on a normal aspect sends effects for each declared arg.
    test-normal-aspect-becomes-computation =
      let
        aspect =
          { host, user }:
          {
            hostName = host;
            userName = user;
          };
        comp = fx.bind.fn { } aspect;
        result = fx.handle {
          handlers = {
            host =
              { param, state }:
              {
                resume = "igloo";
                inherit state;
              };
            user =
              { param, state }:
              {
                resume = "tux";
                inherit state;
              };
          };
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          hostName = "igloo";
          userName = "tux";
        };
      };

    # Static aspect (plain attrset) wraps in fx.pure.
    test-static-aspect-becomes-pure =
      let
        aspect = {
          nixos.enable = true;
        };
        comp = fx.pure aspect;
        result = fx.handle {
          handlers = { };
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          nixos.enable = true;
        };
      };

    # Factory function (empty functionArgs) receives full context.
    test-factory-receives-full-context =
      let
        factory = greeting: { message = greeting; };
        result = fx.handle {
          handlers = { };
          state = { };
        } (fx.pure (factory "hello"));
      in
      {
        expr = result.value;
        expected = {
          message = "hello";
        };
      };

    # Optional args: bind.fn sends with param=true for optional args.
    test-optional-arg-handler-overrides-default =
      let
        aspect =
          {
            host,
            user ? "default-user",
          }:
          {
            hostName = host;
            userName = user;
          };
        comp = fx.bind.fn { } aspect;
        result = fx.handle {
          handlers = {
            host =
              { param, state }:
              {
                resume = "igloo";
                inherit state;
              };
            user =
              { param, state }:
              {
                resume = "tux";
                inherit state;
              };
          };
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          hostName = "igloo";
          userName = "tux";
        };
      };

    # wrapAspect dispatches correctly for each case.
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
