name: sources:
{ config, lib, ... }:
let
  from = lib.flatten [ sources ];
  isOutput = builtins.elem true from;
  denfuls = map (lib.getAttrFromPath [
    "denful"
    name
  ]) (builtins.filter builtins.isAttrs from);

  # Strip _ aliases from external denful to prevent duplication on re-import.
  # The _ → provides alias in aspectSubmodule means evaluated configs contain
  # both _ and provides with identical content. Re-importing both causes
  # listOf options (like includes) to merge duplicates.
  stripAliases = lib.mapAttrs (
    _: v: if builtins.isAttrs v then builtins.removeAttrs v [ "_" ] else v
  );
  sourceModules = map (denful: { config.den.ful.${name} = stripAliases denful; }) denfuls;

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
