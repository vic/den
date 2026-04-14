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
  flake.tests.fx-resolve = {

    # Single static aspect resolves to body with identity envelope.
    test-static-resolves-with-envelope = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        args = {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        };
        result =
          (fx.handle
            {
              handlers = fxLib.handlers.contextHandlers args;
              state = { };
            }
            (
              fxLib.resolve.resolveOne args {
                name = "base";
                meta = { };
                nixos = {
                  networking.hostName = "test";
                };
                includes = [ ];
              }
            )
          ).value;
      in
      {
        expr = {
          name = result.name;
          hasNixos = result ? nixos;
          metaAdapter = result.meta.adapter;
          metaProvider = result.meta.provider;
          includes = result.includes;
        };
        expected = {
          name = "base";
          hasNixos = true;
          metaAdapter = null;
          metaProvider = [ ];
          includes = [ ];
        };
      }
    );

    # Parametric aspect receives host from ctx via effect handler.
    test-parametric-single-arg = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        aspect = {
          name = "web";
          meta = { };
          __functor =
            _:
            { host }:
            {
              nixos.networking.hostName = host;
            };
          __functionArgs = {
            host = false;
          };
          includes = [ ];
        };
        args = {
          ctx = {
            host = "igloo";
          };
          class = "nixos";
          aspect-chain = [ ];
        };
        result =
          (fx.handle {
            handlers = fxLib.handlers.contextHandlers args;
            state = { };
          } (fxLib.resolve.resolveOne args aspect)).value;
      in
      {
        expr = result.nixos.networking.hostName;
        expected = "igloo";
      }
    );

    # Nested includes: parent has parametric child.
    test-nested-parametric-includes = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        child = {
          name = "child";
          meta = { };
          __functor =
            _:
            { host }:
            {
              nixos.networking.hostName = host;
            };
          __functionArgs = {
            host = false;
          };
          includes = [ ];
        };
        parent = {
          name = "parent";
          meta = { };
          nixos = { };
          includes = [ child ];
        };
        result = fxLib.resolve.resolveDeep {
          ctx = {
            host = "igloo";
          };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
      in
      {
        expr = (builtins.head result.includes).nixos.networking.hostName;
        expected = "igloo";
      }
    );

    # Static sub inside parametric parent preserves owned config.
    test-static-sub-in-parametric-parent = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        staticChild = {
          name = "base";
          meta = { };
          nixos = {
            programs.git.enable = true;
          };
          includes = [ ];
        };
        parent = {
          name = "dev";
          meta = { };
          __functor =
            _:
            { user }:
            {
              includes = [ staticChild ];
            };
          __functionArgs = {
            user = false;
          };
          includes = [ ];
        };
        result = fxLib.resolve.resolveDeep {
          ctx = {
            user = "tux";
          };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        childResult = builtins.head result.includes;
      in
      {
        expr = childResult.nixos.programs.git.enable;
        expected = true;
      }
    );

    # Owned stripping: structural keys (includes, name, meta) are separated
    # from owned config. Resolved output has name/meta/includes at top level
    # but the "owned" part is only the config keys (e.g. nixos).
    test-owned-stripping-static = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        args = {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        };
        result =
          (fx.handle
            {
              handlers = fxLib.handlers.contextHandlers args;
              state = { };
            }
            (
              fxLib.resolve.resolveOne args {
                name = "test";
                meta = { };
                nixos = {
                  enable = true;
                };
                includes = [ ];
              }
            )
          ).value;
      in
      {
        expr = {
          hasNixos = result ? nixos;
          hasName = result ? name;
          hasMeta = result ? meta;
          hasIncludes = result ? includes;
          nixosVal = result.nixos;
        };
        expected = {
          hasNixos = true;
          hasName = true;
          hasMeta = true;
          hasIncludes = true;
          nixosVal = {
            enable = true;
          };
        };
      }
    );

    # Parametric aspect: __functor and __functionArgs are NOT in resolved output.
    test-owned-stripping-parametric = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        args = {
          ctx = {
            host = "igloo";
          };
          class = "nixos";
          aspect-chain = [ ];
        };
        result =
          (fx.handle
            {
              handlers = fxLib.handlers.contextHandlers args;
              state = { };
            }
            (
              fxLib.resolve.resolveOne args {
                name = "test";
                meta = { };
                __functor =
                  _:
                  { host }:
                  {
                    nixos = {
                      hostName = host;
                    };
                  };
                __functionArgs = {
                  host = false;
                };
                includes = [ ];
              }
            )
          ).value;
      in
      {
        expr = {
          hasFunctor = result ? __functor;
          hasFunctionArgs = result ? __functionArgs;
          hasNixos = result ? nixos;
          hasName = result ? name;
        };
        expected = {
          hasFunctor = false;
          hasFunctionArgs = false;
          hasNixos = true;
          hasName = true;
        };
      }
    );

    # Meta normalization: adapter defaults to null, provider to [].
    test-meta-normalization = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        args = {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        };
        result =
          (fx.handle
            {
              handlers = fxLib.handlers.contextHandlers args;
              state = { };
            }
            (
              fxLib.resolve.resolveOne args {
                name = "bare";
                includes = [ ];
              }
            )
          ).value;
      in
      {
        expr = result.meta;
        expected = {
          adapter = null;
          provider = [ ];
        };
      }
    );

    # Mixed static and parametric includes resolve correctly.
    test-mixed-static-parametric-includes = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        staticChild = {
          name = "static-child";
          meta = { };
          nixos = {
            a = 1;
          };
          includes = [ ];
        };
        parametricChild = {
          name = "param-child";
          meta = { };
          __functor =
            _:
            { host }:
            {
              nixos = {
                hostName = host;
              };
            };
          __functionArgs = {
            host = false;
          };
          includes = [ ];
        };
        parent = {
          name = "parent";
          meta = { };
          includes = [
            staticChild
            parametricChild
          ];
        };
        result = fxLib.resolve.resolveDeep {
          ctx = {
            host = "igloo";
          };
          class = "nixos";
          aspect-chain = [ ];
        } parent;
        children = result.includes;
      in
      {
        expr = {
          staticA = (builtins.elemAt children 0).nixos.a;
          paramHost = (builtins.elemAt children 1).nixos.hostName;
        };
        expected = {
          staticA = 1;
          paramHost = "igloo";
        };
      }
    );

    # rotate topology: known args resolve identically to direct handle path.
    test-rotate-resolves-same-as-handle = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        aspect = {
          name = "web";
          meta = { };
          __functor =
            _:
            { host }:
            {
              nixos.networking.hostName = host;
            };
          __functionArgs = {
            host = false;
          };
          includes = [ ];
        };
        ctx = {
          host = "igloo";
        };
        resultStrict = fxLib.resolve.resolveOneStrict {
          inherit ctx;
          class = "nixos";
          aspect-chain = [ ];
        } aspect;
        directArgs = {
          inherit ctx;
          class = "nixos";
          aspect-chain = [ ];
        };
        resultDirect =
          (fx.handle {
            handlers = fxLib.handlers.contextHandlers directArgs;
            state = { };
          } (fxLib.resolve.resolveOne directArgs aspect)).value;
      in
      {
        expr = resultStrict.nixos.networking.hostName == resultDirect.nixos.networking.hostName;
        expected = true;
      }
    );

    # rotate topology: multi-arg aspect resolves correctly.
    test-rotate-multi-arg = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        aspect = {
          name = "multi";
          meta = { };
          __functor =
            _:
            { host, user }:
            {
              nixos.networking.hostName = host;
              home.username = user;
            };
          __functionArgs = {
            host = false;
            user = false;
          };
          includes = [ ];
        };
        result = fxLib.resolve.resolveOneStrict {
          ctx = {
            host = "igloo";
            user = "tux";
          };
          class = "nixos";
          aspect-chain = [ ];
        } aspect;
      in
      {
        expr = {
          hostName = result.nixos.networking.hostName;
          username = result.home.username;
        };
        expected = {
          hostName = "igloo";
          username = "tux";
        };
      }
    );

    # Missing required arg produces readable error via rotate path.
    test-missing-arg-throws = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        aspect = {
          name = "broken";
          meta = { };
          __functor =
            _:
            { host }:
            {
              nixos.networking.hostName = host;
            };
          __functionArgs = {
            host = false;
          };
          includes = [ ];
        };
      in
      {
        expectedError = {
          type = "ThrownError";
          msg = "requires";
        };
        expr = fxLib.resolve.resolveOneStrict {
          ctx = {
            user = "tux";
          };
          class = "nixos";
          aspect-chain = [ ];
        } aspect;
      }
    );

    # Static aspect through strict path is identical.
    test-rotate-static-passthrough = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        aspect = {
          name = "static";
          meta = { };
          nixos = {
            enable = true;
          };
          includes = [ ];
        };
        result = fxLib.resolve.resolveOneStrict {
          ctx = { };
          class = "nixos";
          aspect-chain = [ ];
        } aspect;
      in
      {
        expr = result.nixos.enable;
        expected = true;
      }
    );

  };
}
