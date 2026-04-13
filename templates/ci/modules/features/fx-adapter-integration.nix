{
  denTest,
  inputs,
  lib,
  ...
}:
let
  fx = inputs.nix-effects.lib;

  # Standard passthrough + module collection pipeline.
  defaultHandlers =
    fxLib: class:
    {
      "resolve-include" =
        { param, state }:
        {
          resume = [ param ];
          inherit state;
        };
    }
    // (fxLib.adapters.moduleHandler class);

  runPipeline =
    fxLib:
    {
      ctx ? { },
      class ? "nixos",
      aspect-chain ? [ ],
    }:
    aspect:
    let
      comp = fxLib.resolve.resolveDeepEffectful { inherit ctx class aspect-chain; } aspect;
    in
    fx.handle {
      handlers = defaultHandlers fxLib class;
      state = {
        imports = [ ];
      };
    } comp;
in
{
  flake.tests.fx-adapter-integration = {

    # Default pipeline collects class modules from tree.
    test-default-pipeline-collects-modules = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        root = {
          name = "root";
          meta = { };
          nixos = {
            a = 1;
          };
          includes = [
            {
              name = "child1";
              meta = { };
              nixos = {
                b = 2;
              };
              includes = [ ];
            }
            {
              name = "child2";
              meta = { };
              nixos = {
                c = 3;
              };
              includes = [ ];
            }
          ];
        };
        result = runPipeline fxLib { } root;
      in
      {
        expr = builtins.length result.state.imports;
        expected = 2;
      }
    );

    # excludeAspect through full pipeline: tombstoned aspect's module not collected.
    test-exclude-through-pipeline = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        target = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        root = {
          name = "root";
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
        result = runPipeline fxLib { } root;
      in
      {
        expr = builtins.length result.state.imports;
        expected = 1;
      }
    );

    # substituteAspect through full pipeline.
    test-substitute-through-pipeline = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        old = {
          name = "old";
          meta = {
            provider = [ ];
          };
        };
        new = {
          name = "new";
          meta = {
            provider = [ ];
          };
          nixos = {
            replaced = true;
          };
          includes = [ ];
        };
        root = {
          name = "root";
          meta = {
            adapter = fxLib.adapters.substituteAspect old new;
          };
          includes = [
            {
              name = "old";
              meta = {
                provider = [ ];
              };
              nixos = {
                original = true;
              };
              includes = [ ];
            }
          ];
        };
        result = runPipeline fxLib { } root;
      in
      {
        expr = builtins.length result.state.imports;
        expected = 1; # new.nixos only, old.nixos tombstoned
      }
    );

    # includeIf with hasAspect through full pipeline.
    test-includeIf-through-pipeline = denTest (
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
        root = {
          name = "root";
          meta = { };
          includes = [
            sops
            (fxLib.adapters.includeIf (ctx: ctx.hasAspect sops) [ sopsConf ])
          ];
        };
        result = runPipeline fxLib { } root;
      in
      {
        expr = builtins.length result.state.imports;
        expected = 1; # sopsConf.nixos
      }
    );

    # Context root adapter: adapter on root applies to all descendants.
    test-context-root-adapter = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        wayland = {
          name = "wayland";
          meta = {
            provider = [ ];
          };
        };
        root = {
          name = "igloo";
          meta = {
            adapter = fxLib.adapters.excludeAspect wayland;
          };
          includes = [
            {
              name = "desktop";
              meta = {
                provider = [ ];
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
            }
          ];
        };
        result = runPipeline fxLib { } root;
      in
      {
        expr = builtins.length result.state.imports;
        expected = 1; # only x11.nixos
      }
    );

    # Parametric aspect + adapter through pipeline.
    test-parametric-with-adapter = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        target = {
          name = "skip";
          meta = {
            provider = [ ];
          };
        };
        root = {
          name = "root";
          meta = {
            adapter = fxLib.adapters.excludeAspect target;
          };
          includes = [
            {
              name = "web";
              meta = {
                provider = [ ];
              };
              __functor =
                _:
                { host }:
                {
                  nixos.hostName = host;
                  includes = [
                    {
                      name = "skip";
                      meta = {
                        provider = [ ];
                      };
                      nixos = {
                        x = 1;
                      };
                      includes = [ ];
                    }
                    {
                      name = "keep";
                      meta = {
                        provider = [ ];
                      };
                      nixos = {
                        y = 2;
                      };
                      includes = [ ];
                    }
                  ];
                };
              __functionArgs = {
                host = false;
              };
              includes = [ ];
            }
          ];
        };
        result = runPipeline fxLib {
          ctx = {
            host = "igloo";
          };
        } root;
      in
      {
        # web.nixos (hostName) + keep.nixos (y), skip is tombstoned
        expr = builtins.length result.state.imports;
        expected = 2;
      }
    );

  };
}
