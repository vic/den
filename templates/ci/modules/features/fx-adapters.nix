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
  flake.tests.fx-adapters = {

    test-exclude-matches = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        child = {
          name = "drop";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.excludeAspect ref;
        comp = fx.send "resolve-include" child;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
      in
      {
        expr = builtins.isList result.value && (builtins.head result.value).meta.excluded;
        expected = true;
      }
    );

    test-exclude-no-match = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "drop";
          meta = {
            provider = [ ];
          };
        };
        child = {
          name = "keep";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.excludeAspect ref;
        comp = fx.send "resolve-include" child;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
      in
      {
        expr = (builtins.head result.value).name;
        expected = "keep";
      }
    );

    test-exclude-transitive = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "monitoring";
          meta = {
            provider = [ ];
          };
        };
        sub = {
          name = "node-exporter";
          meta = {
            provider = [ "monitoring" ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.excludeAspect ref;
        comp = fx.send "resolve-include" sub;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
      in
      {
        expr = (builtins.head result.value).meta.excluded;
        expected = true;
      }
    );

    test-substitute-replaces = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "old";
          meta = {
            provider = [ ];
          };
        };
        replacement = {
          name = "new";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        child = {
          name = "old";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.substituteAspect ref replacement;
        comp = fx.send "resolve-include" child;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
        items = result.value;
      in
      {
        expr = {
          count = builtins.length items;
          firstExcluded = (builtins.elemAt items 0).meta.excluded;
          firstReplacedBy = (builtins.elemAt items 0).meta.replacedBy;
          secondName = (builtins.elemAt items 1).name;
        };
        expected = {
          count = 2;
          firstExcluded = true;
          firstReplacedBy = "new";
          secondName = "new";
        };
      }
    );

    test-substitute-no-match = denTest (
      { den, ... }:
      let
        fxLib = den.lib.aspects.fx.init fx;
        ref = {
          name = "old";
          meta = {
            provider = [ ];
          };
        };
        replacement = {
          name = "new";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        child = {
          name = "keep";
          meta = {
            provider = [ ];
          };
          includes = [ ];
        };
        handler = fxLib.adapters.substituteAspect ref replacement;
        comp = fx.send "resolve-include" child;
        result = fx.handle {
          handlers = handler;
          state = { };
        } comp;
      in
      {
        expr = (builtins.head result.value).name;
        expected = "keep";
      }
    );

  };
}
