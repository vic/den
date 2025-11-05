name: input:
{ config, lib, ... }:
let
  isLocal = !builtins.isAttrs input;
  isOutput = isLocal && input == true;

  aliasModule = lib.mkAliasOptionModule [ name ] [ "den" "ful" name ];

  type = lib.types.attrsOf config.den.lib.aspects.types.providerType;

  source = if isLocal then { } else input.denful.${name};
  output =
    if isOutput then
      {
        config.flake.denful.${name} = config.den.ful.${name};
        options.flake.denful.${name} = lib.mkOption { inherit type; };
      }
    else
      { };
in
{
  imports = [
    aliasModule
    output
  ];
  config._module.args.${name} = config.den.ful.${name};
  config.den.ful.${name} = source;
  options.den.ful.${name} = lib.mkOption { inherit type; };
}
