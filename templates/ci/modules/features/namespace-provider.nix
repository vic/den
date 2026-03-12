{ denTest, ... }:
{
  flake.tests.namespace-provider = {

    # ctx defined in a provider flake is callable in the consumer
    # and produces the correct names — no doubling.
    test-shared-namespace-ctx = denTest (
      {
        inputs,
        provider,
        funnyNames,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "provider" [ inputs.provider ]) ];
        expr = funnyNames (provider.ctx.simple { }); # call as function
        expected = [ "from-provider-ctx" ];
      }
    );

    # schema defined in a provider flake is usable in consumers.
    test-shared-namespace-schema = denTest (
      {
        inputs,
        provider,
        lib,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "provider" [ inputs.provider ]) ];
        expr =
          let
            # provider exposes a deferred module that we can eval here in the consumer, and it has the expected config.
            mod = lib.evalModules { modules = [ provider.schema.entity ]; };
          in
          mod.config.names;
        expected = [ "provider-entity-schema" ];
      }
    );

  };
}
