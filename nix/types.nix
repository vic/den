lib:
let
  hostsOption = lib.mkOption {
    description = "den hosts definition";
    default = { };
    type = lib.types.attrsOf systemType;
  };

  systemType = lib.types.submodule (
    { name, ... }:
    {
      freeformType = lib.types.attrsOf (hostType name);
    }
  );

  hostType =
    system:
    lib.types.submodule (
      { name, config, ... }:
      {
        options = {
          name = strOpt "host configuration name" name;
          hostName = strOpt "Network hostname" name;
          system = strOpt "platform system" system;
          class = strOpt "os-configuration nix class for host" (
            if lib.hasSuffix "darwin" config.system then "darwin" else "nixos"
          );
          aspect = strOpt "main aspect name of <class>" config.hostName;
          description = strOpt "host description" "${config.class}.${config.hostName}@${config.system}";
          users = lib.mkOption {
            description = "user accounts";
            default = { };
            type = lib.types.attrsOf userType;
          };
        };
      }
    );

  userType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        name = strOpt "user configuration name" name;
        userName = strOpt "user account name" name;
        class = strOpt "home management nix class" "homeManager";
        aspect = strOpt "main aspect name" name;
      };
    }
  );

  strOpt =
    description: default:
    lib.mkOption {
      type = lib.types.str;
      inherit description default;
    };

in
{
  inherit hostsOption;
}
