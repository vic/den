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
  flake.tests.fx-e2e = {

    # Host → user fan-out produces modules from both stages.
    test-host-user-fanout = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        userAspect = {
          name = "user";
          into = _: { };
          provides = { };
          nixos = {
            users.enable = true;
          };
          includes = [ ];
        };
        ctxNs = {
          user = userAspect;
        };
        hostSelf = {
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
          nixos = {
            networking.hostName = "igloo";
          };
          includes = [ ];
        };
        result = fxLib.resolve.fxResolve {
          inherit ctxNs;
          class = "nixos";
          self = hostSelf;
          ctx = {
            host = "igloo";
          };
        };
      in
      {
        expr = builtins.length result.imports >= 2;
        expected = true;
      }
    );

    # Self-provider contributes modules.
    test-self-provider = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        hostSelf = {
          name = "host";
          into = _: { };
          provides = {
            host = ctx: {
              name = "host-provider";
              meta = { };
              nixos = {
                fromProvider = true;
              };
              includes = [ ];
            };
          };
          nixos = {
            base = true;
          };
          includes = [ ];
        };
        result = fxLib.resolve.fxResolve {
          ctxNs = { };
          class = "nixos";
          self = hostSelf;
          ctx = {
            host = "igloo";
          };
        };
      in
      {
        expr = builtins.length result.imports >= 2;
        expected = true;
      }
    );

    # Root adapter excludes aspect.
    test-root-adapter-excludes = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        wayland = {
          name = "wayland";
          meta = {
            provider = [ ];
          };
        };
        hostSelf = {
          name = "host";
          into = _: { };
          provides = { };
          meta = {
            adapter = fxLib.adapters.excludeAspect wayland;
          };
          includes = [
            {
              name = "wayland";
              meta = {
                provider = [ ];
              };
              nixos = {
                wl = true;
              };
              includes = [ ];
            }
            {
              name = "x11";
              meta = {
                provider = [ ];
              };
              nixos = {
                x = true;
              };
              includes = [ ];
            }
          ];
        };
        result = fxLib.resolve.fxResolve {
          ctxNs = { };
          class = "nixos";
          self = hostSelf;
          ctx = { };
        };
      in
      {
        expr = builtins.length result.imports;
        expected = 1;
      }
    );

    # includeIf with hasAspect through full pipeline.
    test-includeIf-e2e = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        sops = {
          name = "sops";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        sopsConf = {
          name = "sops-conf";
          meta = {
            provider = [ ];
          };
          nixos = {
            sops = true;
          };
          includes = [ ];
        };
        hostSelf = {
          name = "host";
          into = _: { };
          provides = { };
          includes = [
            sops
            (fxLib.adapters.includeIf (ctx: ctx.hasAspect sops) [ sopsConf ])
          ];
        };
        result = fxLib.resolve.fxResolve {
          ctxNs = { };
          class = "nixos";
          self = hostSelf;
          ctx = { };
        };
      in
      {
        expr = builtins.length result.imports >= 1;
        expected = true;
      }
    );

  };
}
