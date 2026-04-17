{
  denTest,
  inputs,
  lib,
  ...
}:
{
  flake.tests.fx-handlers = {

    # constantHandler resumes with ctx value for known arg.
    test-parametric-handler-provides-value = denTest({ den, ...}:
      let
        fx = den.lib.fx;
        ctx = {
          host = "igloo";
          user = "tux";
        };
        handlers = builtins.mapAttrs (
          name: value:
          { param, state }:
          {
            resume = value;
            inherit state;
          }
        ) ctx;
        comp = fx.send "host" false;
        result = fx.handle {
          inherit handlers;
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = "igloo";
      });

    # constantHandler provides class.
    test-static-handler-provides-class = denTest({ den, ... }:
      let
        fx = den.lib.fx;
        handlers = {
          "class" =
            { param, state }:
            {
              resume = "nixos";
              inherit state;
            };
        };
        comp = fx.send "class" false;
        result = fx.handle {
          inherit handlers;
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = "nixos";
      });

    # Combined handlers: constantHandler merges ctx + static in one handle call.
    test-combined-handlers = denTest({ den, ... }:
      let
        fx = den.lib.fx;
        ctx = {
          host = "igloo";
        };
        parametric = builtins.mapAttrs (
          _: v:
          { param, state }:
          {
            resume = v;
            inherit state;
          }
        ) ctx;
        static = {
          "class" =
            { param, state }:
            {
              resume = "nixos";
              inherit state;
            };
        };
        aspect =
          { host, class }:
          {
            hostName = host;
            cls = class;
          };
        comp = fx.bind.fn { } aspect;
        result = fx.handle {
          handlers = parametric // static;
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          hostName = "igloo";
          cls = "nixos";
        };
      });

    # Two-layer topology: rotate handles known, outer catches unknown.
    test-rotate-unknown-to-outer = denTest({ den, ... }:
      let
        fx = den.lib.fx;
        ctx = {
          host = "igloo";
        };
        parametric = builtins.mapAttrs (
          _: v:
          { param, state }:
          {
            resume = v;
            inherit state;
          }
        ) ctx;
        aspect =
          { host, missing-arg }:
          {
            inherit host missing-arg;
          };
        comp = fx.bind.fn { } aspect;
        inner = fx.rotate {
          handlers = parametric;
          state = { };
        } comp;
        result = fx.handle {
          handlers."missing-arg" =
            { param, state }:
            {
              resume = "caught";
              inherit state;
            };
          state = { };
        } inner;
      in
      {
        expr = result.value.value;
        expected = {
          host = "igloo";
          missing-arg = "caught";
        };
      });

    # constantHandler merges ctx values.
    test-constantHandler-denTest = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
        handlers = den.lib.aspects.fx.handlers.constantHandler {
          host = "igloo";
          class = "nixos";
        };
        aspect =
          { host, class }:
          {
            hostName = host;
            cls = class;
          };
        comp = fx.bind.fn { } aspect;
        result = fx.handle {
          inherit handlers;
          state = { };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          hostName = "igloo";
          cls = "nixos";
        };
      }
    );

    # chainHandler: push appends identity to includesChain.
    test-chain-push-appends = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
        comp = fx.bind (fx.send "chain-push" { identity = "a"; }) (
          _: fx.send "chain-push" { identity = "b"; }
        );
        result = fx.handle {
          handlers = den.lib.aspects.fx.handlers.chainHandler;
          state = {
            includesChain = [ ];
          };
        } comp;
      in
      {
        expr = result.state.includesChain;
        expected = [
          "a"
          "b"
        ];
      }
    );

    # chainHandler: pop removes last element.
    test-chain-pop-removes-last = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
        comp = fx.bind (fx.send "chain-push" { identity = "a"; }) (
          _: fx.bind (fx.send "chain-push" { identity = "b"; }) (_: fx.send "chain-pop" null)
        );
        result = fx.handle {
          handlers = den.lib.aspects.fx.handlers.chainHandler;
          state = {
            includesChain = [ ];
          };
        } comp;
      in
      {
        expr = result.state.includesChain;
        expected = [ "a" ];
      }
    );

    # chainHandler: pop on empty list throws (push/pop mismatch).
    test-chain-pop-empty-throws = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
        comp = fx.send "chain-pop" null;
        raw = fx.handle {
          handlers = den.lib.aspects.fx.handlers.chainHandler;
          state = {
            includesChain = [ ];
          };
        } comp;
        # Force the includesChain thunk inside tryEval to catch the throw.
        result = builtins.tryEval (builtins.deepSeq raw.state.includesChain raw.state.includesChain);
      in
      {
        expr = result.success;
        expected = false;
      }
    );

  };
}
