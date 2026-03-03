{
  den,
  lib,
  inputs,
  ...
}:
let
  maidClass = "maid";
  maidOsClasses = [
    "nixos"
  ];

  hostConf =
    { host, ... }:
    {
      options.nix-maid = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = den.lib.host-has-user-with-class host maidClass;
        };
        module = lib.mkOption {
          type = lib.types.deferredModule;
          default = inputs.nix-maid.nixosModules.default;
        };
      };
    };

  maidDetect =
    { host }:
    let
      isOsSupported = builtins.elem host.class maidOsClasses;
      maidUsers = builtins.filter (u: lib.elem maidClass u.classes) (lib.attrValues host.users);
      hasMaidUsers = builtins.length maidUsers > 0;
      isMaidHost = host.nix-maid.enable && isOsSupported && hasMaidUsers;
    in
    lib.optional isMaidHost { inherit host; };

  ctx.host.into.maid-host = maidDetect;

  ctx.maid-host._.maid-host =
    { host }:
    {
      ${host.class}.imports = [ host.nix-maid.module ];
    };
in
{
  den.ctx = ctx;
  den.base.host.imports = [ hostConf ];
}
