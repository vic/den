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
  flake.tests.fx-identity = {

    test-aspectPath-with-provider = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        a = {
          name = "sub";
          meta = {
            provider = [ "monitoring" ];
          };
        };
      in
      {
        expr = fxLib.adapters.aspectPath a;
        expected = [
          "monitoring"
          "sub"
        ];
      }
    );

    test-aspectPath-no-provider = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        a = {
          name = "base";
          meta = { };
        };
      in
      {
        expr = fxLib.adapters.aspectPath a;
        expected = [ "base" ];
      }
    );

    test-pathKey = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
      in
      {
        expr = fxLib.adapters.pathKey [
          "monitoring"
          "sub"
        ];
        expected = "monitoring/sub";
      }
    );

    test-toPathSet = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
      in
      {
        expr = fxLib.adapters.toPathSet [
          [ "a" ]
          [
            "b"
            "c"
          ]
        ];
        expected = {
          "a" = true;
          "b/c" = true;
        };
      }
    );

    test-tombstone-shape = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        a = {
          name = "drop";
          meta = {
            provider = [ ];
          };
          includes = [ "x" ];
        };
        ts = fxLib.adapters.tombstone a { excludedFrom = "parent"; };
      in
      {
        expr = {
          name = ts.name;
          excluded = ts.meta.excluded;
          originalName = ts.meta.originalName;
          excludedFrom = ts.meta.excludedFrom;
          includes = ts.includes;
        };
        expected = {
          name = "~drop";
          excluded = true;
          originalName = "drop";
          excludedFrom = "parent";
          includes = [ ];
        };
      }
    );

  };
}
