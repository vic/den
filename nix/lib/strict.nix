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

            optionPath =
              if lib.lists.hasPrefix [ "flake" ] path then
                "den.schema.flake.options.${decl.name}"
              else if lib.lists.hasPrefix [ "den" "default" ] path then
                "den.schema.aspect.options.${decl.name}"
              else if lib.lists.hasPrefix [ "den" "ful" ] path then
                "den.schema.namespace.options.${lib.last path}.${decl.name}"
              else
                lib.elemAt path 1;
          in
          throw ''
            STRICT MODE

            Attempted to set the option "${decl.name}" in "${lib.join "." path}" but no explicit definition exists. If this wasn't a mistake, disable STRICT mode or configure an option. e.g.

            ${optionPath} = lib.mkOption { ... };

            See https://documentation.example
          ''
        );
    };
  };
}
