{
  den,
  lib,
  inputs,
  ...
}:
let
  inherit (den.lib.home-env) makeHomeEnv;

  result = makeHomeEnv {
    className = "maid";
    supportedOses = [ "nixos" ];
    optionPath = "nix-maid";
    inputsPath = "nix-maid";
    getModule = { host, ... }: inputs.nix-maid."${host.class}Modules".default;
    forwardPathFn =
      { user, ... }:
      [
        "users"
        "users"
        user.userName
        "maid"
      ];
  };

in
{
  den.ctx = result.ctx;
  den.schema.host.imports = [ result.hostConf ];
}
