name: sources:
{ config, lib, ... }:
let
  from = lib.flatten [ sources ];
  isOutput = builtins.elem true from;
  denfuls = map (lib.getAttrFromPath [
    "denful"
    name
  ]) (builtins.filter builtins.isAttrs from);

  sourceModules = map (denful: { config.den.ful.${name} = denful; }) denfuls;

  aliasModule = lib.mkAliasOptionModule [ name ] [ "den" "ful" name ];

  outputModule =
    if isOutput then
      {
        config.flake.denful.${name} = config.den.ful.${name};
      }
    else
      { };
in
{
  imports = sourceModules ++ [
    aliasModule
    outputModule
  ];
  config._module.args.${name} = config.den.ful.${name};
}
