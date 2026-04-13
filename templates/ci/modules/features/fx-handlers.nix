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
  flake.tests.fx-handlers = {

    # Parametric handler resumes with ctx value for known arg.
    test-parametric-handler-provides-value =
      let
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
      };

    # Static handler provides class.
    test-static-handler-provides-class =
      let
        handlers = {
          "class" =
            { param, state }:
            {
              resume = "nixos";
              inherit state;
            };
          "aspect-chain" =
            { param, state }:
            {
              resume = [ "root" ];
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
      };

    # Combined handlers: parametric + static in one handle call.
    test-combined-handlers =
      let
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
          "aspect-chain" =
            { param, state }:
            {
              resume = [ ];
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
      };

    # Two-layer topology: rotate handles known, outer catches unknown.
    test-rotate-unknown-to-outer =
      let
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
      };

    # contextHandlers merges parametric + static.
    test-contextHandlers-denTest = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        handlers = fxLib.contextHandlers {
          ctx = {
            host = "igloo";
          };
          class = "nixos";
          aspect-chain = [ ];
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

  };
}
