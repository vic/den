{ denTest, inputs, ... }:
{

  flake.tests.angle-brackets = {

    test-den-dot-access = denTest (
      { den, __findFile, ... }:
      {
        _module.args.__findFile = den.lib.__findFile;
        expr = <den.lib> ? owned;
        expected = true;
      }
    );

    test-den-slash-provides = denTest (
      {
        den,
        __findFile,
        lib,
        ...
      }:
      {
        _module.args.__findFile = den.lib.__findFile;
        expr = lib.isFunction <den/import-tree/host>;
        expected = true;
      }
    );

    test-aspect-without-prefix = denTest (
      {
        den,
        __findFile,
        lib,
        ...
      }:
      {
        _module.args.__findFile = den.lib.__findFile;
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = { };
        expr = <igloo> ? provides;
        expected = true;
      }
    );

    test-aspect-provides = denTest (
      {
        den,
        __findFile,
        lib,
        ...
      }:
      {
        _module.args.__findFile = den.lib.__findFile;
        den.aspects.foo.provides.bar.nixos = { };
        expr = <foo/bar> ? nixos;
        expected = true;
      }
    );

    test-namespace-access = denTest (
      {
        den,
        __findFile,
        ns,
        ...
      }:
      {
        _module.args.__findFile = den.lib.__findFile;

        imports = [ (inputs.den.namespace "ns" true) ];

        ns.moo.silly = true;

        expr = <ns/moo> ? silly;
        expected = true;
      }
    );

    test-deep-nested-provides = denTest (
      {
        den,
        __findFile,
        igloo,
        ...
      }:
      {
        _module.args.__findFile = den.lib.__findFile;

        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.foo.provides.bar.provides.baz.nixos.programs.fish.enable = true;
        den.aspects.igloo.includes = [ <foo/bar/baz> ];

        expr = igloo.programs.fish.enable;
        expected = true;
      }
    );

  };

}
