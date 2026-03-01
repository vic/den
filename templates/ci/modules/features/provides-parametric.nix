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
          ns.bar._.baz
          ns.a
          ns.a._.b
          ns.a._.c
          ns.a._.d
          ns.a._.d._.e
        ];

        expr = igloo.networking.hostName;
        expected = "pinguino";
      }
    );

  };

}
