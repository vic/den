lib:
let
  hostsOption = lib.mkOption {
    description = documentation;
    default = { };
    type = lib.types.attrsOf hostType;
  };

  documentation = ''
    Definitions of hosts with their users.

    The following are all `den` conventions and are not mandated by the Dendritic pattern.

    Each host has a single dendritic entry module: `flake.modules.<class>.<aspect>`.

    <class> is something like `nixos` or `darwin`, `systemManager`, or any other OS nix class.

    By default, <class> is auto-detected from <system>, if it has suffix "darwin" then "darwin" else "nixos".
    By default, aspect is <hostName>. Can be set to any value explicitly.

    Each user also has single dendritic entry module: `flake.modules.<class>.<aspect>`.
    By default, <class> is `homeManager` but can also be `hjem` or any other home management nix class.
    By default, the aspect is "<userName>". Can be set to any value explicitly.

    These `aspect` names have no special meaning for the Dendritic pattern and can have any custom
    arbitrary value.
  '';

  hostType = lib.types.submodule (
    { name, config, ... }:
    {
      options = {
        name = strOpt "host configuration name" name;
        hostName = strOpt "Network hostname" name;
        system = strOpt "platform system" null;
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
