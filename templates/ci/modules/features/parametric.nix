{ denTest, ... }:
{
  flake.tests.parametric = {
    test-parametric-forwards-context = denTest (
      {
        den,
        igloo,
        ...
      }:
      let
        foo = den.lib.parametric {
          includes = [
            (
              { host, ... }:
              {
                nixos.users.users.tux.description = host.name;
              }
            )
          ];
        };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ foo ];

        expr = igloo.users.users.tux.description;
        expected = "igloo";
      }
    );

    test-parametric-owned-config = denTest (
      {
        den,
        igloo,
        ...
      }:
      let
        foo = den.lib.parametric {
          nixos.networking.hostName = "from-parametric-owned";
          includes = [ ];
        };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ foo ];

        expr = igloo.networking.hostName;
        expected = "from-parametric-owned";
      }
    );

    test-parametric-fixedTo = denTest (
      {
        den,
        igloo,
        ...
      }:
      let
        foo =
          { host, ... }:
          den.lib.parametric.fixedTo { planet = "Earth"; } {
            includes = [
              (
                { planet, ... }:
                {
                  nixos.users.users.tux.description = planet;
                }
              )
            ];
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ foo ];

        expr = igloo.users.users.tux.description;
        expected = "Earth";
      }
    );

    test-parametric-expands = denTest (
      {
        den,
        igloo,
        ...
      }:
      let
        foo = den.lib.parametric.expands { planet = "Earth"; } {
          includes = [
            (
              {
                host,
                planet,
                ...
              }:
              {
                nixos.users.users.tux.description = "${host.name}/${planet}";
              }
            )
          ];
        };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ foo ];

        expr = igloo.users.users.tux.description;
        expected = "igloo/Earth";
      }
    );

    test-never-matches-aspect-skipped = denTest (
      {
        den,
        igloo,
        ...
      }:
      let
        never-matches =
          { never-exists, ... }:
          {
            nixos.networking.hostName = "NEVER";
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = den.lib.parametric {
          includes = [
            den._.hostname
            never-matches
          ];
        };

        expr = igloo.networking.hostName;
        expected = "igloo";
      }
    );

    test-parametric-fixedTo-atLeast = denTest (
      {
        den,
        lib,
        inputs,
        ...
      }:
      let
        inherit (den.lib.parametric) fixedTo;
        testAspect = name: include: {
          nixos.test = [ "excluded-owned-${name}" ];

          _.host =
            { host }:
            {
              nixos.test = [ "${host}-${name}" ];
            };

          _.host-user =
            { host, user }:
            {
              nixos.test = [ "${host}-${user}-${name}" ];
            };

          _.static =
            { class, ... }:
            {
              ${class}.test = [ "excluded-static-${name}" ];
            };

          includes = include ++ [
            den.aspects.${name}._.host
            den.aspects.${name}._.host-user
            den.aspects.${name}._.static
          ];
        };
        testOptionProvider = args: aspect: {
          includes = [
            aspect
            {
              __functor = self: _: {
                nixos.options.test = lib.mkOption { type = lib.types.listOf lib.types.str; };
              };
              __functionArgs =
                args
                |> map (arg: {
                  name = arg;
                  value = false;
                })
                |> builtins.listToAttrs;
            }
          ];
        };
      in
      {
        den.aspects.inner = testAspect "inner" [ ];
        den.aspects.outer = testAspect "outer" [ den.aspects.inner ];

        expr =
          {
            exactlyHost = {
              ctx = {
                host = "igloo";
              };
              functor = fixedTo.exactly;
            };
            exactlyHostUser = {
              ctx = {
                host = "igloo";
                user = "tux";
              };
              functor = fixedTo.exactly;
            };
            upToHost = {
              ctx = {
                host = "igloo";
              };
              functor = fixedTo.upTo;
            };
            upToHostUser = {
              ctx = {
                host = "igloo";
                user = "tux";
              };
              functor = fixedTo.upTo;
            };
            atLeastHost = {
              ctx = {
                host = "igloo";
              };
              functor = fixedTo.atLeast;
            };
            # This test case errors because atLeast tries to call { host }: with { host, user } causing an error
            # this is IMO incorrect behaviour, but would technically be a breaking change if people are using
            # args@{ host, ... } which is why I introduced a new kind "upTo" which uses the canTake.atLeast
            # predicate but only calls the function with the attributes it expects
            # atLeastHostUser = {
            #   ctx = {
            #     host = "igloo";
            #     user = "tux";
            #   };
            #   parametricFunctor = atLeast.fixed;
            # };
          }
          |> lib.mapAttrs (
            _: test:
            den.aspects.outer
            |> testOptionProvider (builtins.attrNames test.ctx)
            |> (lib.flip test.functor) test.ctx
            |> den.lib.aspects.resolve "nixos" [ ]
            |> (nixos: inputs.nixpkgs.lib.evalModules { modules = [ nixos ]; })
            |> (x: x.config.test)
          );

        expected = {
          atLeastHost = [
            "igloo-inner"
            "igloo-outer"
          ];
          exactlyHost = [
            "igloo-inner"
            "igloo-outer"
          ];
          exactlyHostUser = [
            "igloo-tux-inner"
            "igloo-tux-outer"
          ];
          upToHost = [
            "igloo-inner"
            "igloo-outer"
          ];
          upToHostUser = [
            "igloo-tux-inner"
            "igloo-inner"
            "igloo-tux-outer"
            "igloo-outer"
          ];
        };
      }
    );
  };
}
