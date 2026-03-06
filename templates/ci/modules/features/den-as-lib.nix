{
  inputs,
  lib,
  config,
  ...
}:
let
  denPath = inputs.den.outPath;
  denModule = (import denPath).nixModule inputs;
in
{
  flake.tests.den-as-lib = {

    test-expose-lib-functions =
      let
        den-lib = import denPath { inherit lib config inputs; };
        expr = den-lib.canTake.exactly { x = 1; } ({ x, y }: { });
        expected = false;
      in
      {
        inherit expr expected;
      };

    test-module-usable-in-any-module-system =
      let
        ev = lib.evalModules { modules = [ denModule ]; };
        expr = ev.config.den ? lib.parametric;
        expected = true;
      in
      {
        inherit expr expected;
      };

    test-module-has-empty-ctx =
      let
        ev = lib.evalModules { modules = [ denModule ]; };
        expr = lib.attrNames ev.config.den.ctx;
        expected = [ ];
      in
      {
        inherit expr expected;
      };

    test-module-has-empty-aspects =
      let
        ev = lib.evalModules { modules = [ denModule ]; };
        expr = lib.attrNames ev.config.den.aspects;
        expected = [ ];
      in
      {
        inherit expr expected;
      };

    test-module-has-no-nixos-domain =
      let
        names = [
          "hosts"
          "homes"
          "schema"
          "default"
          "provides"
          "ful"
        ];
        ev = lib.evalModules { modules = [ denModule ]; };
        expr = builtins.all (name: !ev.config.den ? ${name}) names;
        expected = true;
      in
      {
        inherit expr expected;
      };

    test-module-can-resolve-custom-domain =
      let
        ev = lib.evalModules {
          modules = [
            denModule
            module
          ];
        };

        module =
          { den, lib, ... }:
          {
            den.ctx.foo.provides.foo =
              { name }:
              {
                my.names = [ "foo ${name}" ];
              };
            den.ctx.foo.into.bar = { name }: lib.singleton { shout = lib.toUpper name; };
            den.ctx.foo.provides.bar =
              { shout }:
              {
                my.names = [ "foo shouted ${shout}" ];
              };

            den.ctx.bar.provides.bar =
              { shout }:
              {
                my.names = [ "bar ${shout}" ];
              };

            den.aspects.foobar.includes = [
              (den.ctx.foo { name = "good"; })
            ];
          };

        myMod = ev.config.den.aspects.foobar.resolve { class = "my"; };
        nameMod.options.names = lib.mkOption { type = lib.types.listOf lib.types.str; };
        ev2 = lib.evalModules {
          modules = [
            nameMod
            myMod
          ];
        };

        expr = ev2.config.names;
        expected = [
          "foo shouted GOOD"
          "bar GOOD"
          "foo good"
        ];
      in
      {
        inherit expr expected;
      };

  };
}
