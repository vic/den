{ denTest, lib, ... }:
{
  flake.tests.aspect-path = {

    test-aspectPath-named = denTest (
      { den, ... }:
      {
        den.aspects.foo.nixos = { };
        expr = den.lib.aspects.adapters.aspectPath den.aspects.foo;
        expected = [ "foo" ];
      }
    );

    test-aspectPath-with-provider = denTest (
      { den, ... }:
      {
        den.aspects.monitoring = {
          nixos = { };
          provides.node-exporter.nixos = { };
        };
        expr = den.lib.aspects.adapters.aspectPath den.aspects.monitoring._.node-exporter;
        expected = [
          "monitoring"
          "node-exporter"
        ];
      }
    );

    # excludeAspect: excluded include becomes a tombstone (visible in trace)
    test-excludeAspect-tombstone-in-trace = denTest (
      { den, ... }:
      {
        den.aspects.foo.includes = [
          den.aspects.bar
          den.aspects.baz
        ];
        den.aspects.foo.meta.adapter =
          inherited: den.lib.aspects.adapters.excludeAspect den.aspects.baz inherited;
        den.aspects.bar.nixos = { };
        den.aspects.baz.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.foo;
        # baz appears as tombstone (~baz, no children)
        expected.trace = [
          "foo"
          [ "bar" ]
          [ "~baz" ]
        ];
      }
    );

    # excludeAspect: tombstone contributes no modules to the build
    test-excludeAspect-no-modules = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = { };
        den.aspects.igloo.includes = [
          den.aspects.bar
          den.aspects.baz
        ];
        den.aspects.igloo.meta.adapter =
          inherited: den.lib.aspects.adapters.excludeAspect den.aspects.baz inherited;
        den.aspects.bar.nixos.environment.sessionVariables.msg = "bar";
        den.aspects.baz.nixos.environment.sessionVariables.msg = "baz";

        # only bar's module is included, baz is excluded
        expr = igloo.environment.sessionVariables.msg;
        expected = "bar";
      }
    );

    # excludeAspect: propagates through subtree
    test-excludeAspect-propagates-to-subtree = denTest (
      { den, ... }:
      {
        den.aspects.root.includes = [ den.aspects.role ];
        den.aspects.root.meta.adapter =
          inherited: den.lib.aspects.adapters.excludeAspect den.aspects.baz inherited;
        den.aspects.role.includes = [
          den.aspects.bar
          den.aspects.baz
        ];
        den.aspects.bar.nixos = { };
        den.aspects.baz.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.root;
        # baz tombstone appears in role's subtree
        expected.trace = [
          "root"
          [
            "role"
            [ "bar" ]
            [ "~baz" ]
          ]
        ];
      }
    );

    # excludeAspect: by provider path
    test-excludeAspect-by-provider = denTest (
      { den, ... }:
      {
        den.aspects.monitoring = {
          nixos = { };
          provides.node-exporter.nixos = { };
          provides.alerting.nixos = { };
        };
        den.aspects.server.includes = with den.aspects; [
          monitoring
          monitoring._.node-exporter
          monitoring._.alerting
        ];
        den.aspects.server.meta.adapter =
          inherited: den.lib.aspects.adapters.excludeAspect den.aspects.monitoring._.node-exporter inherited;

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.server;
        # node-exporter tombstone visible, alerting kept
        expected.trace = [
          "server"
          [ "monitoring" ]
          [ "~node-exporter" ]
          [ "alerting" ]
        ];
      }
    );

    # excludeAspect: excluding a parent also excludes its providers
    test-excludeAspect-cascades-to-providers = denTest (
      { den, ... }:
      {
        den.aspects.monitoring = {
          nixos = { };
          provides.node-exporter.nixos = { };
          provides.alerting.nixos = { };
        };
        den.aspects.server.includes = with den.aspects; [
          monitoring
          monitoring._.node-exporter
          monitoring._.alerting
        ];
        den.aspects.server.meta.adapter =
          inherited: den.lib.aspects.adapters.excludeAspect den.aspects.monitoring inherited;

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.server;
        # monitoring and all its providers excluded
        expected.trace = [
          "server"
          [ "~monitoring" ]
          [ "~node-exporter" ]
          [ "~alerting" ]
        ];
      }
    );

    # substituteAspect: replaced include becomes tombstone + replacement
    test-substituteAspect-replaces = denTest (
      { den, ... }:
      {
        den.aspects.foo.includes = [
          den.aspects.bar
          den.aspects.baz
        ];
        den.aspects.foo.meta.adapter =
          inherited: den.lib.aspects.adapters.substituteAspect den.aspects.bar den.aspects.qux inherited;
        den.aspects.bar.nixos = { };
        den.aspects.baz.nixos = { };
        den.aspects.qux.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.foo;
        # bar tombstone + qux replacement, baz unchanged
        expected.trace = [
          "foo"
          [ "~bar" ]
          [ "qux" ]
          [ "baz" ]
        ];
      }
    );

    # substituteAspect: replacement modules are used in build
    test-substituteAspect-build-uses-replacement = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = { };
        den.aspects.igloo.includes = [ den.aspects.bar ];
        den.aspects.igloo.meta.adapter =
          inherited: den.lib.aspects.adapters.substituteAspect den.aspects.bar den.aspects.qux inherited;
        den.aspects.bar.nixos.environment.sessionVariables.msg = "bar";
        den.aspects.qux.nixos.environment.sessionVariables.msg = "qux";

        # qux's module is used, not bar's
        expr = igloo.environment.sessionVariables.msg;
        expected = "qux";
      }
    );

    # substituteAspect: propagates through subtree
    test-substituteAspect-propagates = denTest (
      { den, ... }:
      {
        den.aspects.root.includes = [ den.aspects.role ];
        den.aspects.root.meta.adapter =
          inherited: den.lib.aspects.adapters.substituteAspect den.aspects.baz den.aspects.qux inherited;
        den.aspects.role.includes = [
          den.aspects.bar
          den.aspects.baz
        ];
        den.aspects.bar.nixos = { };
        den.aspects.baz.nixos = { };
        den.aspects.qux.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.root;
        # baz tombstone + qux in role's subtree
        expected.trace = [
          "root"
          [
            "role"
            [ "bar" ]
            [ "~baz" ]
            [ "qux" ]
          ]
        ];
      }
    );

    # structuredTrace: produces entry objects with metadata
    test-structuredTrace-entries = denTest (
      { den, lib, ... }:
      {
        den.aspects.foo.includes = [ den.aspects.bar ];
        den.aspects.foo.meta.adapter =
          inherited: den.lib.aspects.adapters.excludeAspect den.aspects.bar inherited;
        den.aspects.bar.nixos = { };

        expr =
          let
            result = den.lib.aspects.resolve.withAdapter den.lib.aspects.adapters.structuredTrace "nixos" den.aspects.foo;
            entries = builtins.filter (e: e.name != "<anon>" && !(lib.hasPrefix "[definition " e.name)) result.trace;
          in
          map (e: { inherit (e) name excluded; }) entries;
        expected = [
          { name = "foo"; excluded = false; }
          { name = "bar"; excluded = true; }
        ];
      }
    );

    # perHost parametric aspects should appear in trace by name
    test-perHost-visible-in-trace = denTest (
      { den, ... }:
      {
        den.aspects.role.includes = with den.aspects; [
          leaf
          param
        ];
        den.aspects.leaf.nixos = { };
        den.aspects.param = den.lib.perHost (
          { host }:
          {
            nixos = { };
          }
        );

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.role;
        expected.trace = [
          "role"
          [ "leaf" ]
          [
            "param"
            [ "[definition 1-entry 1]" ]
          ]
        ];
      }
    );

  };
}
