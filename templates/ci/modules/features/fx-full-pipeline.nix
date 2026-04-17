{
  denTest,
  inputs,
  lib,
  ...
}:
{
  flake.tests.fx-full-pipeline = {

    # Minimal: single aspect with nixos config, collects module.
    test-minimal-pipeline = denTest (
      { den, ... }:
      let
        self = {
          name = "host";
          meta = { };
          nixos = {
            networking.hostName = "test";
          };
          includes = [ ];
        };
        result = den.lib.aspects.fx.pipeline.fxFullResolve {
          class = "nixos";
          inherit self;
          ctx = { };
        };
      in
      {
        expr = builtins.length (result.state.imports null);
        expected = 1;
      }
    );

    # Root + child: both class modules collected.
    test-root-and-child-modules = denTest (
      { den, ... }:
      let
        self = {
          name = "host";
          meta = { };
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
        result = den.lib.aspects.fx.pipeline.fxFullResolve {
          class = "nixos";
          inherit self;
          ctx = { };
        };
      in
      {
        expr = builtins.length (result.state.imports null);
        expected = 2;
      }
    );

    # fxResolve returns { imports } shape.
    test-fxResolve-shape = denTest (
      { den, ... }:
      let
        self = {
          name = "host";
          meta = { };
          nixos = {
            a = 1;
          };
          includes = [ ];
        };
        result = den.lib.aspects.fx.pipeline.fxResolve {
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

    # Constraint (exclude) through full pipeline.
    test-adapter-through-pipeline = denTest (
      { den, ... }:
      let
        target = {
          name = "drop";
          meta.provider = [ ];
        };
        self = {
          name = "host";
          meta = {
            handleWith = den.lib.aspects.fx.constraints.exclude target;
          };
          includes = [
            {
              name = "keep";
              meta.provider = [ ];
              nixos = {
                a = 1;
              };
              includes = [ ];
            }
            {
              name = "drop";
              meta.provider = [ ];
              nixos = {
                b = 2;
              };
              includes = [ ];
            }
          ];
        };
        result = den.lib.aspects.fx.pipeline.fxResolve {
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
        self = {
          name = "host";
          meta = { };
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
        result = den.lib.aspects.fx.pipeline.fxFullResolve {
          class = "nixos";
          inherit self;
          ctx = {
            host = "igloo";
          };
        };
      in
      {
        expr = builtins.length (result.state.imports null);
        expected = 1;
      }
    );

  };
}
