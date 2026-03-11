{
  den,
  lib,
  inputs,
  ...
}:
let
  inherit (den.lib.home-env) makeHomeEnv;

  result = makeHomeEnv {
    className = "hjem";
    optionPath = "hjem";
    inputsPath = "hjem";
    getModule = { host, ... }: inputs.hjem."${host.class}Modules".default;
    forwardPathFn =
      { user, ... }:
      [
        "hjem"
        "users"
        user.userName
      ];
  };

in
{
  den.ctx = result.ctx;
  den.schema.host.imports = [ result.hostConf ];
}
