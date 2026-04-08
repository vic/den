{ denTest, lib, ... }:
{
  flake.tests.adapter-propagation = {

    # --- Aspect-level meta.adapter ---

    test-resolve-honors-meta-adapter = denTest (
      { den, ... }:
      {
        den.aspects.foo.includes = [ den.aspects.bar ];
        den.aspects.foo.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: (a.name or null) != "bar") inherited;
        den.aspects.bar.nixos = { };

        expr = (den.lib.aspects.resolve "nixos" den.aspects.foo) ? imports;
        expected = true;
      }
    );

    test-tags-includes-with-adapter = denTest (
      { den, ... }:
      {
        den.aspects.parent.includes = [ den.aspects.child ];
        den.aspects.parent.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: (a.name or null) != "baz") inherited;
        den.aspects.child.includes = [ den.aspects.baz ];
        den.aspects.baz.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.parent;
        # baz tombstone visible in trace
        expected.trace = [
          "parent"
          [
            "child"
            [ "~baz" ]
          ]
        ];
      }
    );

    test-child-inherits-parent-adapter = denTest (
      { den, ... }:
      {
        den.aspects.parent.includes = [ den.aspects.child ];
        den.aspects.parent.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: (a.name or null) != "excluded") inherited;
        den.aspects.child.includes = [
          den.aspects.kept
          den.aspects.excluded
        ];
        den.aspects.kept.nixos = { };
        den.aspects.excluded.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.parent;
        expected.trace = [
          "parent"
          [
            "child"
            [ "kept" ]
            [ "~excluded" ]
          ]
        ];
      }
    );

    test-deep-chain-a-excludes-c-through-b = denTest (
      { den, ... }:
      {
        den.aspects.a.includes = [ den.aspects.b ];
        den.aspects.a.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: (a.name or null) != "c") inherited;
        den.aspects.b.includes = [
          den.aspects.c
          den.aspects.d
        ];
        den.aspects.c.nixos = { };
        den.aspects.d.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.a;
        expected.trace = [
          "a"
          [
            "b"
            [ "~c" ]
            [ "d" ]
          ]
        ];
      }
    );

    test-diamond-a-excludes-d-through-both-paths = denTest (
      { den, ... }:
      {
        den.aspects.a.includes = [
          den.aspects.b
          den.aspects.c
        ];
        den.aspects.a.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: (a.name or null) != "d") inherited;
        den.aspects.b.includes = [ den.aspects.d ];
        den.aspects.c.includes = [ den.aspects.d ];
        den.aspects.d.nixos = { };

        expr = with den.lib.aspects; resolve.withAdapter adapters.trace "nixos" den.aspects.a;
        expected.trace = [
          "a"
          [
            "b"
            [ "~d" ]
          ]
          [
            "c"
            [ "~d" ]
          ]
        ];
      }
    );

    # --- Context-level meta.adapter ---

    test-ctx-carries-meta-adapter = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo = { };

        den.ctx.host.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: a.name != "foo") inherited;

        expr = (den.ctx.host { host = den.hosts.x86_64-linux.igloo; }).meta.adapter != null;
        expected = true;
      }
    );

    test-ctx-meta-adapter-null-when-unset = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo = { };

        expr = (den.ctx.host { host = den.hosts.x86_64-linux.igloo; }).meta.adapter;
        expected = null;
      }
    );

    # --- Cross-stage: host adapter filters at user level ---

    # Host context adapter transitively filters nested aspects.
    # blocked-deep is two levels below igloo but still excluded.
    test-ctx-host-adapter-filters-transitively = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.ctx.host.meta.adapter =
          inherited: den.lib.aspects.adapters.filter (a: (a.name or null) != "blocked") inherited;

        den.aspects.igloo.includes = [ den.aspects.parent ];
        den.aspects.parent.includes = [
          den.aspects.allowed
          den.aspects.blocked
        ];
        den.aspects.allowed.nixos.environment.sessionVariables.ALLOWED = "yes";
        den.aspects.blocked.nixos.environment.sessionVariables.BLOCKED = "yes";

        expr = {
          hasAllowed = igloo.environment.sessionVariables ? ALLOWED;
          hasBlocked = igloo.environment.sessionVariables ? BLOCKED;
        };
        expected = {
          hasAllowed = true;
          hasBlocked = false;
        };
      }
    );

  };
}
