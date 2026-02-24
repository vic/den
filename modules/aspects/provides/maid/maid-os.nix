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
  maidModule = host: host.maid-module or inputs.nix-maid.nixosModules.default;

  maidDetect =
    { host }:
    let
      isOsSupported = builtins.elem host.class maidOsClasses;
      hasMaidModule = (host ? maid-module) || (inputs ? nix-maid);
      maidUsers = builtins.filter (u: lib.elem maidClass u.classes) (lib.attrValues host.users);
      hasMaidUsers = builtins.length maidUsers > 0;
      isMaidHost = isOsSupported && hasMaidUsers && hasMaidModule;
    in
    lib.optional isMaidHost { inherit host; };

in
{
  den.ctx.host.into.maid-host = maidDetect;

  den.ctx.maid-host._.maid-host =
    { host }:
    {
      ${host.class}.imports = [ (maidModule host) ];
    };
}
