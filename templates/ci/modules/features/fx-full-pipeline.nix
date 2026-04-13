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
  flake.tests.fx-full-pipeline = {

    # Minimal: single aspect with nixos config, collects module.
    test-minimal-pipeline = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        self = {
          name = "host";
          into = _: { };
          provides = { };
          nixos = {
            networking.hostName = "test";
          };
          includes = [ ];
        };
        result = fxLib.resolve.fxFullResolve {
          ctxNs = { };
          class = "nixos";
          inherit self;
          ctx = { };
        };
      in
      {
        expr = builtins.length result.state.imports;
        expected = 1;
      }
    );

    # Root + child: both class modules collected.
    test-root-and-child-modules = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        self = {
          name = "host";
          into = _: { };
          provides = { };
          nixos = {
            a = 1;
          };
          includes = [
            {
              name = "child";
              meta = { };
              nixos = {
                b = 2;
              };
              includes = [ ];
            }
          ];
        };
        result = fxLib.resolve.fxFullResolve {
          ctxNs = { };
          class = "nixos";
          inherit self;
          ctx = { };
        };
      in
      {
        expr = builtins.length result.state.imports;
        expected = 2;
      }
    );

    # fxResolve returns { imports } shape.
    test-fxResolve-shape = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        self = {
          name = "host";
          into = _: { };
          provides = { };
          nixos = {
            a = 1;
          };
          includes = [ ];
        };
        result = fxLib.resolve.fxResolve {
          ctxNs = { };
          class = "nixos";
          inherit self;
          ctx = { };
        };
      in
      {
        expr = result ? imports && builtins.isList result.imports;
        expected = true;
      }
    );

    # Adapter through full pipeline.
    test-adapter-through-pipeline = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        target = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        self = {
          name = "host";
          into = _: { };
          provides = { };
          meta = {
            adapter = fxLib.adapters.excludeAspect target;
          };
          includes = [
            {
              name = "keep";
              meta = {
                provider = [ ];
              };
              nixos = {
                a = 1;
              };
              includes = [ ];
            }
            {
              name = "drop";
              meta = {
                provider = [ ];
              };
              nixos = {
                b = 2;
              };
              includes = [ ];
            }
          ];
        };
        result = fxLib.resolve.fxResolve {
          ctxNs = { };
          class = "nixos";
          inherit self;
          ctx = { };
        };
      in
      {
        expr = builtins.length result.imports;
        expected = 1;
      }
    );

    # Parametric child through full pipeline.
    test-parametric-through-pipeline = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        self = {
          name = "host";
          into = _: { };
          provides = { };
          includes = [
            {
              name = "web";
              meta = { };
              __functor =
                _:
                { host }:
                {
                  nixos.hostName = host;
                };
              __functionArgs = {
                host = false;
              };
              includes = [ ];
            }
          ];
        };
        result = fxLib.resolve.fxFullResolve {
          ctxNs = { };
          class = "nixos";
          inherit self;
          ctx = {
            host = "igloo";
          };
        };
      in
      {
        expr = builtins.length result.state.imports;
        expected = 1;
      }
    );

  };
}
