# Tests for context stage tagging and __ctxTrace.
{ denTest, lib, ... }:
{
  flake.tests.ctx-trace = {

    # ctxApply produces __ctxTrace with traversal items.
    test-ctxTrace-present = denTest (
      { den, ... }:
      let
        host = (builtins.head (builtins.attrValues (builtins.head (builtins.attrValues den.hosts))));
        root = den.ctx.host { inherit host; };
      in
      {
        den.hosts.x86_64-linux.test-host.users.tux = { };
        den.aspects.test-host.nixos =
          { ... }:
          {
            networking.hostName = "test";
          };
        expr = builtins.isList (root.__ctxTrace or null) && builtins.length root.__ctxTrace >= 1;
        expected = true;
      }
    );

    # __ctxTrace items have required fields.
    test-ctxTrace-item-shape = denTest (
      { den, ... }:
      let
        host = (builtins.head (builtins.attrValues (builtins.head (builtins.attrValues den.hosts))));
        root = den.ctx.host { inherit host; };
        firstItem = builtins.head root.__ctxTrace;
      in
      {
        den.hosts.x86_64-linux.test-host.users.tux = { };
        den.aspects.test-host.nixos =
          { ... }:
          {
            networking.hostName = "test";
          };
        expr = {
          hasKey = firstItem ? key;
          hasSelfName = firstItem ? selfName;
          hasPrevName = firstItem ? prevName;
          hasCtxKeys = firstItem ? ctxKeys;
          hasEntityNames = firstItem ? entityNames;
          hasProvideNames = firstItem ? provideNames;
        };
        expected = {
          hasKey = true;
          hasSelfName = true;
          hasPrevName = true;
          hasCtxKeys = true;
          hasEntityNames = true;
          hasProvideNames = true;
        };
      }
    );

    # Includes carry __ctxStage and __ctxKind tags.
    test-includes-have-stage-tags = denTest (
      { den, ... }:
      let
        host = (builtins.head (builtins.attrValues (builtins.head (builtins.attrValues den.hosts))));
        root = den.ctx.host { inherit host; };
        tagged = builtins.filter (i: builtins.isAttrs i && i ? __ctxStage) (root.includes or [ ]);
      in
      {
        den.hosts.x86_64-linux.test-host.users.tux = { };
        den.aspects.test-host.nixos =
          { ... }:
          {
            networking.hostName = "test";
          };
        expr = builtins.length tagged >= 1;
        expected = true;
      }
    );

  };
}
