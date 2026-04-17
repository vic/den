{
  denTest,
  inputs,
  lib,
  ...
}:
{
  flake.tests.fx-resolve = {

    # Static aspect resolves with identity envelope through the pipeline.
    test-static-resolves-with-envelope = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
        aspect = {
          name = "base";
          meta = { };
          nixos = {
            networking.hostName = "test";
          };
          includes = [ ];
        };
        comp = den.lib.aspects.fx.aspect.aspectToEffect aspect;
        result = fx.handle {
          handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
            class = "nixos";
            ctx = { };
          };
          state = den.lib.aspects.fx.pipeline.defaultState;
        } comp;
      in
      {
        expr = {
          name = result.value.name;
          hasNixos = result.value ? nixos;
          includes = result.value.includes;
        };
        expected = {
          name = "base";
          hasNixos = true;
          includes = [ ];
        };
      }
    );

    # Parametric aspect receives host from ctx via effect handler.
    test-parametric-single-arg = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
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
        comp = den.lib.aspects.fx.aspect.aspectToEffect aspect;
        result = fx.handle {
          handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
            class = "nixos";
            ctx = {
              host = "igloo";
            };
          };
          state = den.lib.aspects.fx.pipeline.defaultState;
        } comp;
      in
      {
        expr = result.value.nixos.networking.hostName;
        expected = "igloo";
      }
    );

    # Nested includes: parent has parametric child.
    test-nested-parametric-includes = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
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
        comp = den.lib.aspects.fx.aspect.aspectToEffect parent;
        result = fx.handle {
          handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
            class = "nixos";
            ctx = {
              host = "igloo";
            };
          };
          state = den.lib.aspects.fx.pipeline.defaultState;
        } comp;
      in
      {
        expr = (builtins.head result.value.includes).nixos.networking.hostName;
        expected = "igloo";
      }
    );

    # Static sub inside parametric parent preserves owned config.
    test-static-sub-in-parametric-parent = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
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
        comp = den.lib.aspects.fx.aspect.aspectToEffect parent;
        result = fx.handle {
          handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
            class = "nixos";
            ctx = {
              user = "tux";
            };
          };
          state = den.lib.aspects.fx.pipeline.defaultState;
        } comp;
        childResult = builtins.head result.value.includes;
      in
      {
        expr = childResult.nixos.programs.git.enable;
        expected = true;
      }
    );

    # Owned stripping: structural keys separated from config keys.
    test-owned-stripping-static = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
        aspect = {
          name = "test";
          meta = { };
          nixos = {
            enable = true;
          };
          includes = [ ];
        };
        comp = den.lib.aspects.fx.aspect.aspectToEffect aspect;
        result =
          (fx.handle {
            handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
              class = "nixos";
              ctx = { };
            };
            state = den.lib.aspects.fx.pipeline.defaultState;
          } comp).value;
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
        fx = den.lib.fx;
        aspect = {
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
        };
        comp = den.lib.aspects.fx.aspect.aspectToEffect aspect;
        result =
          (fx.handle {
            handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
              class = "nixos";
              ctx = {
                host = "igloo";
              };
            };
            state = den.lib.aspects.fx.pipeline.defaultState;
          } comp).value;
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

    # Mixed static and parametric includes resolve correctly.
    test-mixed-static-parametric-includes = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
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
        comp = den.lib.aspects.fx.aspect.aspectToEffect parent;
        result = fx.handle {
          handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
            class = "nixos";
            ctx = {
              host = "igloo";
            };
          };
          state = den.lib.aspects.fx.pipeline.defaultState;
        } comp;
        children = result.value.includes;
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

    # Pipeline produces consistent results across invocations.
    test-pipeline-consistent-results = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
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
        comp1 = den.lib.aspects.fx.aspect.aspectToEffect aspect;
        result1 =
          (fx.handle {
            handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
              class = "nixos";
              inherit ctx;
            };
            state = den.lib.aspects.fx.pipeline.defaultState;
          } comp1).value;

        comp2 = den.lib.aspects.fx.aspect.aspectToEffect aspect;
        result2 =
          (fx.handle {
            handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
              class = "nixos";
              inherit ctx;
            };
            state = den.lib.aspects.fx.pipeline.defaultState;
          } comp2).value;
      in
      {
        expr = result1.nixos.networking.hostName == result2.nixos.networking.hostName;
        expected = true;
      }
    );

    # rotate topology: multi-arg aspect resolves correctly.
    test-rotate-multi-arg = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
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
        comp = den.lib.aspects.fx.aspect.aspectToEffect aspect;
        result =
          (fx.handle {
            handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
              class = "nixos";
              ctx = {
                host = "igloo";
                user = "tux";
              };
            };
            state = den.lib.aspects.fx.pipeline.defaultState;
          } comp).value;
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

    # Missing required arg produces readable error.
    test-missing-arg-throws = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
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
        comp = den.lib.aspects.fx.aspect.aspectToEffect aspect;
      in
      {
        expectedError = {
          type = "ThrownError";
          msg = "host";
        };
        expr = fx.handle {
          handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
            class = "nixos";
            ctx = {
              user = "tux";
            };
          };
          state = den.lib.aspects.fx.pipeline.defaultState;
        } comp;
      }
    );

    # Static aspect through pipeline is identical.
    test-rotate-static-passthrough = denTest (
      { den, ... }:
      let
        fx = den.lib.fx;
        aspect = {
          name = "static";
          meta = { };
          nixos = {
            enable = true;
          };
          includes = [ ];
        };
        comp = den.lib.aspects.fx.aspect.aspectToEffect aspect;
        result =
          (fx.handle {
            handlers = den.lib.aspects.fx.pipeline.defaultHandlers {
              class = "nixos";
              ctx = { };
            };
            state = den.lib.aspects.fx.pipeline.defaultState;
          } comp).value;
      in
      {
        expr = result.nixos.enable;
        expected = true;
      }
    );

    # composeHandlers: b's resume wins, a's state updates applied on top.
    test-composeHandlers-resume-from-b-state-from-a =
      let
        a = {
          "test-effect" =
            { param, state }:
            {
              resume = "a-resume";
              state = state // {
                fromA = true;
              };
            };
        };
        b = {
          "test-effect" =
            { param, state }:
            {
              resume = "b-resume";
              state = state // {
                fromB = true;
              };
            };
        };
      in
      denTest (
        { den, ... }:
        let
        fx = den.lib.fx;
          composed = den.lib.aspects.fx.pipeline.composeHandlers a b;
          comp = fx.send "test-effect" null;
          result = fx.handle {
            handlers = composed;
            state = { };
          } comp;
        in
        {
          expr = {
            resume = result.value;
            hasA = result.state.fromA or false;
            hasB = result.state.fromB or false;
          };
          expected = {
            resume = "b-resume";
            hasA = true;
            hasB = true;
          };
        }
      );

  };
}
