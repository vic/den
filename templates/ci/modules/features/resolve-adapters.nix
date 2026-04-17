{ denTest, lib, ... }:
{
  flake.tests.resolve-adapters = {

    test-basic-trace-includes = denTest (
      {
        den,
        lib,
        trace,
        ...
      }:
      {
        den.fxPipeline = false;

        den.aspects.foo.includes = [ den.aspects.bar ];
        den.aspects.bar.includes = [ den.aspects.baz ];
        den.aspects.baz.nixos = { };

        expr = trace "nixos" den.aspects.foo;
        expected.trace = [
          "foo"
          [
            "bar"
            [ "baz" ]
          ]
        ];
      }
    );

    test-filter-compose-with-trace-includes = denTest (
      {
        den,
        lib,
        trace,
        ...
      }:
      {
        den.fxPipeline = false;

        den.aspects.foo.includes = [ den.aspects.bar ];
        den.aspects.bar.includes = [ den.aspects.baz ];
        den.aspects.baz.nixos = { };

        expr =
          let
            outer = den.lib.aspects.adapters.filter (aspect: aspect.name != "bar");
          in
          trace.over outer "nixos" den.aspects.foo;
        expected.trace = [
          "foo"
          [ ]
        ];
      }
    );

    test-host-conditional-aspect-inclusion = denTest (
      {
        den,
        lib,
        iceberg,
        ...
      }:
      {
        den.fxPipeline = false;
        den.hosts.x86_64-linux.igloo = { };
        den.hosts.x86_64-linux.iceberg = { };

        den.aspects.foo.meta.key = "foo";
        den.aspects.foo.nixos.environment.sessionVariables.message = "foo";

        den.aspects.bar.nixos.environment.sessionVariables.message = "bar";

        # host igloo includes foo
        den.aspects.igloo.includes = [ den.aspects.foo ];

        # host iceberg feature detects if foo is available at host igloo
        den.aspects.iceberg.includes =
          let
            inherit (den.lib.aspects) resolve;
            inherit (den.hosts.x86_64-linux) igloo;

            iglooAspect = den.ctx.host { host = igloo; };
            detectFoo = resolve.withAdapter (hasAspectWithKey "foo") "nixos" iglooAspect;

            hasAspectWithKey =
              key:
              { aspect, recurse, ... }:
              {
                found =
                  aspect.meta.key or null == key || lib.any (i: (recurse i).found or false) (aspect.includes or [ ]);
              };

          in
          lib.optional detectFoo.found den.aspects.bar;

        expr = iceberg.environment.sessionVariables.message;
        expected = "bar";
      }
    );

  };
}
