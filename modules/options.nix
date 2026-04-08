{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (config) den;
  types = import ./../nix/lib/types.nix {
    inherit
      inputs
      lib
      den
      config
      ;
  };

  # Schema entries auto-inject config.resolved when den.ctx.${kind} exists.
  # Context args are derived from the entity's _module.args, filtered to
  # known context kinds so framework args don't leak through.
  schemaEntryType =
    let
      base = lib.types.deferredModule;
    in
    base
    // {
      merge =
        loc: defs:
        let
          kind = lib.last loc;
          merged = base.merge loc defs;
          resolvedCtx =
            { config, ... }:
            {
              options.resolved = lib.mkOption {
                description = "The resolved aspect for this ${kind}, produced by den.ctx.${kind}.";
                readOnly = true;
                type = lib.types.raw;
                default = den.ctx.${kind} (
                  lib.filterAttrs (n: _: den.ctx ? ${n}) config._module.args // { ${kind} = config; }
                );
              };
            };
        in
        if den.ctx ? ${kind} then
          {
            imports = [
              merged
              resolvedCtx
            ];
          }
        else
          merged;
    };

  schemaOption = lib.mkOption {
    description = "freeform deferred modules per entity kind";
    defaultText = lib.literalExpression "{ }";
    default = { };
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf schemaEntryType;
    };
  };
in
{
  options.den.hosts = types.hostsOption;
  options.den.homes = types.homesOption;
  options.den.schema = schemaOption;
  config.den.schema = {
    conf = { };
    host.imports = [ den.schema.conf ];
    user.imports = [ den.schema.conf ];
    home.imports = [ den.schema.conf ];
  };
}
