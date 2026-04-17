{ denTest, inputs, ... }:
{

  flake.tests.provides-parametric = {

    test-parametric-inside-provides = denTest (
      {
        den,
        ns,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        imports = [ (inputs.den.namespace "ns" false) ];

        ns.foo = den.lib.parametric { };
        ns.bar.provides.baz = den.lib.parametric { };
        ns.a = den.lib.parametric {
          provides.b = den.lib.parametric { };
          provides.c = den.lib.parametric { };
          provides.d = den.lib.parametric {
            provides.e = den.lib.parametric { nixos.networking.hostName = "pinguino"; };
          };
        };

        den.aspects.igloo.includes = [
          ns.foo
          ns.bar.provides.baz
          ns.a
          ns.a.provides.b
          ns.a.provides.c
          ns.a.provides.d
          ns.a.provides.d.provides.e
        ];

        expr = igloo.networking.hostName;
        expected = "pinguino";
      }
    );

  };

  # Bare function sub-aspects receive parametric context from parent.
  flake.tests.provides-parametric-bare-fn = {

    test-bare-fn-sub-aspect-receives-host = denTest (
      {
        den,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        imports = [
          {
            den.aspects.monitoring =
              { host, ... }:
              {
                includes = [ den.aspects.monitoring.provides.node-exporter ];
              };
          }
          {
            den.aspects.monitoring.provides.node-exporter =
              { host, ... }:
              {
                nixos.networking.hostName = "${host.name}-monitored";
              };
          }
        ];

        den.aspects.igloo.includes = [ den.aspects.monitoring ];

        expr = igloo.networking.hostName;
        expected = "igloo-monitored";
      }
    );

    test-static-parent-bare-fn-sub = denTest (
      {
        den,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        imports = [
          {
            den.aspects.monitoring.includes = [ den.aspects.monitoring.provides.agent ];
          }
          {
            den.aspects.monitoring.provides.agent =
              { host, ... }:
              {
                nixos.networking.hostName = "${host.name}-agent";
              };
          }
        ];

        den.aspects.igloo.includes = [ den.aspects.monitoring ];

        expr = igloo.networking.hostName;
        expected = "igloo-agent";
      }
    );
  };

}
