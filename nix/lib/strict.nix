{ lib, ... }:
{
  _module.freeformType = lib.mkOptionType {
    name = "strict type";
    typeMerge = outer: {
      merge =
        path: decls:
        (
          let
            decl = lib.pipe decls [
              lib.head
              (lib.getAttr "value")
              lib.attrsToList
              lib.head
            ];

            explanation =
              if lib.lists.hasPrefix [ "flake" ] path then
                ''
                  Attempted to set the flake output option "${decl.name}" but no definition exists.
                  If this wasn't a mistake, disable STRICT mode, import the flake output or configure an option. e.g.

                  # Import the flake output from den
                  imports = [ inputs.den.flakeOutputs.${decl.name} ];

                  # Import all flake outputs from den
                  imports = [ inputs.den.flakeOuputs.all ];

                  # Configure a custom flake output
                  den.schema.flake.options.${decl.name} = lib.mkOption { ... };
                ''
              else if lib.lists.hasPrefix [ "den" "aspects" ] path then
                ''
                  Attempted to set the option "${decl.name}" on the aspect "${lib.join "." path}" but no definition exists.
                  If this wasn't a mistake, disable STRICT mode or configure an option. e.g.

                  # For all aspects
                  den.schema.aspect.options.${decl.name} = lib.mkOption { ... };

                  # For a specific aspect
                  den.aspect.${lib.last path}.options.${decl.name} = lib.mkOption { ... };

                  # As a reusable option
                  den._.option.options.${decl.name} = lib.mkOption { ... };
                  den.aspect.${lib.last path}.includes = [ den._.option ];
                ''
              else if lib.lists.hasPrefix [ "den" "ful" ] path then
                ''
                  Attempted to set the option "${lib.last path}.${decl.name}" on the namespace "${lib.elemAt path 2}" but no definition exists.
                  If this wasn't a mistake, disable STRICT mode or configure an option. e.g.

                  # If you're attempting to set up a non-aspect part of the namespace like schema, ctx, or lib
                  den.schema.namespace.options.${lib.last path}.${decl.name} = lib.mkOption { ... };
                ''
              else
                let
                  kind = if lib.lists.any (x: x == "users") path then "user" else "host";
                in
                ''
                  Attempted to set the option "${decl.name}" on the ${kind} "${lib.join "." path}" but no definition exists.
                  If this wasn't a mistake, disable STRICT mode or configure an option. e.g.

                  # For all ${kind}s
                  den.schema.${kind}.options.${decl.name} = lib.mkOption { ... };

                  # For all entities
                  den.schema.conf.options.${decl.name} = lib.mkOption { ... };

                  # For a specific ${kind}
                  ${lib.join "." path}.options.${decl.name} = lib.mkOption { ... };
                '';
          in
          throw ''
            STRICT MODE
            ${explanation}
            See https://den.oeiuwq.com/reference/schema/
          ''
        );
    };
  };
}
