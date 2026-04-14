{
  denTest,
  inputs,
  lib,
  ...
}:
let
  fx = inputs.nix-effects.lib;

  mkHandlers = {
    "ctx-traverse" =
      { param, state }:
      {
        resume = null;
        inherit state;
      };
    "ctx-seen" =
      { param, state }:
      let
        isFirst = !((state.seen or { }) ? ${param});
      in
      {
        resume = { inherit isFirst; };
        state = state // {
          seen = (state.seen or { }) // {
            ${param} = true;
          };
        };
      };
    "ctx-provider" =
      { param, state }:
      let
        inherit (param)
          kind
          self
          key
          prev
          prevCtx
          ;
      in
      if kind == "self" then
        {
          resume = self.provides.${self.name} or null;
          inherit state;
        }
      else if kind == "cross" && prev != null then
        let
          pathHead = lib.head (lib.splitString "." key);
          provFn = prev.provides.${pathHead} or null;
        in
        {
          resume = if provFn != null then provFn prevCtx else null;
          inherit state;
        }
      else
        {
          resume = null;
          inherit state;
        };
    "ctx-emit" =
      { param, state }:
      {
        resume = param.aspect;
        inherit state;
      };
  };
in
{
  flake.tests.fx-ctx-apply = {

    # Single stage: self with no into transitions.
    test-single-stage = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        self = {
          name = "host";
          into = _: { };
          provides = { };
        };
        comp = fxLib.ctxApply.ctxApplyEffectful { } self { host = "igloo"; };
        result = fx.handle {
          handlers = mkHandlers;
          state = {
            seen = { };
          };
        } comp;
      in
      {
        expr = builtins.isList result.value && builtins.length result.value >= 1;
        expected = true;
      }
    );

    # Into transition: host → user.
    test-into-transition = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        userAspect = {
          name = "user";
          into = _: { };
          provides = { };
          includes = [ ];
        };
        ctxNs = {
          user = userAspect;
        };
        self = {
          name = "host";
          into =
            { host, ... }:
            {
              user = [
                {
                  inherit host;
                  user = "tux";
                }
              ];
            };
          provides = { };
        };
        comp = fxLib.ctxApply.ctxApplyEffectful ctxNs self { host = "igloo"; };
        result = fx.handle {
          handlers = mkHandlers;
          state = {
            seen = { };
          };
        } comp;
      in
      {
        expr = builtins.length result.value >= 2;
        expected = true;
      }
    );

    # Dedup: same key second time gets isFirst=false.
    test-dedup =
      let
        comp = fx.bind (fx.send "ctx-seen" "k") (
          a:
          fx.bind (fx.send "ctx-seen" "k") (
            b:
            fx.pure {
              first = a.isFirst;
              second = b.isFirst;
            }
          )
        );
        result = fx.handle {
          handlers."ctx-seen" =
            { param, state }:
            let
              isFirst = !((state.seen or { }) ? ${param});
            in
            {
              resume = { inherit isFirst; };
              state = state // {
                seen = (state.seen or { }) // {
                  ${param} = true;
                };
              };
            };
          state = {
            seen = { };
          };
        } comp;
      in
      {
        expr = result.value;
        expected = {
          first = true;
          second = false;
        };
      };

    # Self-provider resolved.
    test-self-provider =
      let
        provFn = ctx: { name = "provided"; };
        comp = fx.send "ctx-provider" {
          kind = "self";
          self = {
            name = "host";
            provides = {
              host = provFn;
            };
          };
          ctx = { };
          key = "host";
          prev = null;
          prevCtx = null;
        };
        result = fx.handle {
          handlers."ctx-provider" =
            { param, state }:
            if param.kind == "self" then
              {
                resume = param.self.provides.${param.self.name} or null;
                inherit state;
              }
            else
              {
                resume = null;
                inherit state;
              };
          state = { };
        } comp;
      in
      {
        expr = (result.value { }).name;
        expected = "provided";
      };

    # ctx-traverse fires, recorded in state.
    test-traverse-fires = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        self = {
          name = "host";
          into = _: { };
          provides = { };
        };
        comp = fxLib.ctxApply.ctxApplyEffectful { } self { host = "igloo"; };
        result = fx.handle {
          handlers = mkHandlers // {
            "ctx-traverse" =
              { param, state }:
              {
                resume = null;
                state = state // {
                  stages = (state.stages or [ ]) ++ [ param.key ];
                };
              };
          };
          state = {
            seen = { };
            stages = [ ];
          };
        } comp;
      in
      {
        expr = builtins.elem "host" result.state.stages;
        expected = true;
      }
    );

  };
}
