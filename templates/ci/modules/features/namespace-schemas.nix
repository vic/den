{ denTest, ... }:
{
  flake.tests.namespace-schemas = {

    # A namespace has its own aspects that can be resolved.
    test-namespace-aspects-resolve = denTest (
      {
        den,
        aux,
        inputs,
        funnyNames,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "aux" [ ]) ];
        aux.my-aspect.funny.names = [ "hello" ];

        expr = funnyNames aux.my-aspect;
        expected = [ "hello" ];
      }
    );

    # Namespace ctx dispatches includes through its own pipeline.
    test-namespace-ctx-dispatches = denTest (
      {
        den,
        aux,
        funnyNames,
        inputs,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "aux" [ ]) ];
        aux.my-aspect.includes = [
          (
            { word, ... }:
            {
              funny.names = [ word ];
            }
          )
        ];
        aux.ctx.entry.provides.entry = { word }: den.lib.parametric.fixedTo { inherit word; } aux.my-aspect;

        expr = funnyNames (aux.ctx.entry { word = "greet"; });
        expected = [ "greet" ];
      }
    );

    # Two independent namespaces don't share aspects or ctx.
    test-two-namespaces-independent = denTest (
      {
        alpha,
        beta,
        funnyNames,
        inputs,
        ...
      }:
      {
        imports = [
          (inputs.den.namespace "alpha" [ ])
          (inputs.den.namespace "beta" [ ])
        ];
        alpha.shared.funny.names = [ "alpha" ];
        beta.shared.funny.names = [ "beta" ];

        expr = (funnyNames alpha.shared) ++ (funnyNames beta.shared);
        expected = [
          "alpha"
          "beta"
        ];
      }
    );

    # Namespace aspects are fully independent from den.aspects.
    test-namespace-independent-from-den = denTest (
      {
        den,
        aux,
        igloo,
        funnyNames,
        inputs,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "aux" [ ]) ];
        aux.igloo.funny.names = [ "aux" ];
        den.aspects.igloo.funny.names = [ "den" ];
        den.hosts.x86_64-linux.igloo = { };

        expr = (funnyNames aux.igloo) ++ (funnyNames den.aspects.igloo);
        expected = [
          "aux"
          "den"
        ];
      }
    );

    # Nested ctx works within a namespace.
    test-namespace-nested-ctx = denTest (
      {
        den,
        aux,
        funnyNames,
        inputs,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "aux" [ ]) ];
        aux.my-aspect.includes = [
          (
            { word, ... }:
            {
              funny.names = [ word ];
            }
          )
        ];
        aux.ctx.ns.leaf.provides.leaf =
          { word }: den.lib.parametric.fixedTo { inherit word; } aux.my-aspect;

        expr = funnyNames (aux.ctx.ns.leaf { word = "nested"; });
        expected = [ "nested" ];
      }
    );

    # Namespace schema accepts freeform deferredModule entries per entity kind.
    test-namespace-schema-freeform = denTest (
      {
        aux,
        funnyNames,
        inputs,
        lib,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "aux" [ ]) ];
        aux.schema.widget =
          { lib, ... }:
          {
            options.funny.names = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            config.funny.names = [ "widget-schema" ];
          };

        expr =
          let
            mod = lib.evalModules { modules = [ aux.schema.widget ]; };
          in
          mod.config.funny.names;
        expected = [ "widget-schema" ];
      }
    );

    # Multiple schema entries for different entity kinds coexist.
    test-namespace-schema-multiple-keys = denTest (
      {
        aux,
        inputs,
        lib,
        ...
      }:
      {
        imports = [ (inputs.den.namespace "aux" [ ]) ];
        aux.schema.alpha = {
          _secret = "alpha";
        };
        aux.schema.beta = {
          _secret = "beta";
        };

        expr = builtins.attrNames aux.schema;
        expected = [
          "alpha"
          "beta"
        ];
      }
    );

  };
}
