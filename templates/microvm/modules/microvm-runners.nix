# for each host exposes microvm declaredRunner (if exists) as package output of this flake.
# feel free to remove or adapt.
{
  den,
  lib,
  config,
  inputs,
  ...
}:
let
  microvmRunners = lib.pipe den.hosts [
    lib.attrValues
    (lib.concatMap lib.attrValues)
    (map (
      host:
      let
        osConf = lib.attrByPath host.intoAttr null config.flake;
        vmRunner = osConf.config.microvm.declaredRunner or null;
        package = lib.optionalAttrs (vmRunner != null) {
          ${host.system}.${host.name} = vmRunner;
        };
      in
      package
    ))
  ];
in
{
  config.flake.packages = lib.mkMerge microvmRunners;
}
