{
  inputs,
  lib,
  den,
  ...
}@top:
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
        freeformType = lib.types.attrsOf lib.types.anything;
        imports = [ den.schema.host ];
        config._module.args.host = config;
        options = {
          name = strOpt "host configuration name" name;
          hostName = strOpt "Network hostname" config.name;
          system = strOpt "platform system" system;
          class = strOpt "os-configuration nix class for host" (
            if lib.hasSuffix "darwin" config.system then "darwin" else "nixos"
          );
          aspect = strOpt "main aspect name of <class>" config.name;
          description = strOpt "host description" "${config.class}.${config.hostName}@${config.system}";
          users = lib.mkOption {
            description = "user accounts";
            default = { };
            type = lib.types.attrsOf (userType config);
          };
          instantiate = lib.mkOption {
            description = ''
              Function used to instantiate the OS configuration.

              Depending on class, defaults to:
              `darwin`: inputs.darwin.lib.darwinSystem
              `nixos`:  inputs.nixpkgs.lib.nixosSystem
              `systemManager`: inputs.system-manager.lib.makeSystemConfig

              Set explicitly if you need:

              - a custom input name, eg, nixos-unstable.
              - adding specialArgs when absolutely required.
            '';
            example = lib.literalExpression "inputs.nixpkgs.lib.nixosSystem";
            type = lib.types.raw;
            default =
              {
                nixos = inputs.nixpkgs.lib.nixosSystem;
                darwin = inputs.darwin.lib.darwinSystem;
                systemManager = inputs.system-manager.lib.makeSystemConfig;
              }
              .${config.class};
          };
          intoAttr = lib.mkOption {
            description = ''
              Flake attr where to add the named result of this configuration.
              flake.<intoAttr>.<name>

              Depending on class, defaults to:
              `darwin`: darwinConfigurations
              `nixos`:  nixosConfigurations
              `systemManager`: systemConfigs
            '';
            example = lib.literalExpression ''[  "nixosConfigurations" hostName ]'';
            type = lib.types.listOf lib.types.str;
            default =
              {
                nixos = [
                  "nixosConfigurations"
                  config.name
                ];
                darwin = [
                  "darwinConfigurations"
                  config.name
                ];
                systemManager = [
                  "systemConfigs"
                  config.name
                ];
              }
              .${config.class};
          };
          mainModule = lib.mkOption {
            internal = true;
            visible = false;
            readOnly = true;
            type = lib.types.deferredModule;
            default = mainModule config den.ctx.host "host";
          };
        };
      }
    );

  userType =
    host:
    lib.types.submodule (
      { name, config, ... }:
      {
        freeformType = lib.types.attrsOf lib.types.anything;
        imports = [ den.schema.user ];
        config._module.args.host = host;
        config._module.args.user = config;
        options = {
          name = strOpt "user configuration name" name;
          userName = strOpt "user account name" name;
          classes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "home management nix classes";
            default = [ "user" ];
          };
          aspect = strOpt "main aspect name" config.name;
        };
      }
    );

  strOpt =
    description: default:
    lib.mkOption {
      type = lib.types.str;
      inherit description default;
    };

  homesOption = lib.mkOption {
    description = "den standalone home-manager configurations";
    default = { };
    type = lib.types.attrsOf homeSystemType;
  };

  homeSystemType = lib.types.submodule (
    { name, ... }:
    {
      freeformType = lib.types.attrsOf (homeType name);
    }
  );

  homeType =
    system:
    lib.types.submodule (
      { name, config, ... }:
      let
        nameWithHost = lib.hasInfix "@" name;
        userName = if nameWithHost then lib.head (builtins.split "@" name) else name;
        hostName = if nameWithHost then lib.last (builtins.split "@" name) else null;
        hostByName = den.hosts.${system}.${hostName};

        homeManagerConfiguration =
          if nameWithHost then
            { pkgs, modules }:
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs modules;
              extraSpecialArgs.osConfig = lib.attrByPath ([ "flake" ] ++ hostByName.intoAttr) top.config;
            }
          else
            inputs.home-manager.lib.homeManagerConfiguration;
      in
      {
        freeformType = lib.types.attrsOf lib.types.anything;
        imports = [ den.schema.home ];
        config._module.args.home = config;
        config._module.args.host = hostByName;
        config._module.args.user = hostByName.users.${userName};
        options = {
          name = strOpt "home configuration name" name;
          userName = strOpt "user account name" userName;
          hostName = strOpt "host name" hostName;
          system = strOpt "platform system" system;
          class = strOpt "home management nix class" "homeManager";
          aspect = strOpt "main aspect name" userName;
          description = strOpt "home description" "home.${config.name}@${config.system}";
          pkgs = lib.mkOption {
            description = ''
              nixpkgs instance used to build the home configuration.
            '';
            example = lib.literalExpression ''inputs.nixpkgs.legacyPackages.''${home.system}'';
            type = lib.types.raw;
            default = inputs.nixpkgs.legacyPackages.${config.system};
          };
          instantiate = lib.mkOption {
            description = ''
              Function used to instantiate the home configuration.

              Depending on class, defaults to:
              `homeManager`: inputs.home-manager.lib.homeManagerConfiguration

              Set explicitly if you need:

              - a custom input name, eg, home-manager-unstable.
              - adding extraSpecialArgs when absolutely required.
            '';
            example = lib.literalExpression "inputs.home-manager.lib.homeManagerConfiguration";
            type = lib.types.raw;
            default =
              {
                homeManager = homeManagerConfiguration;
              }
              .${config.class};
          };
          intoAttr = lib.mkOption {
            description = ''
              Flake attr where to add the named result of this configuration.
              flake.<intoAttr>.<name>

              Depending on class, defaults to:
              `homeManager`: homeConfigurations
            '';
            example = lib.literalExpression ''[  "homeConfigurations" userName ]'';
            type = lib.types.listOf lib.types.str;
            default =
              {
                homeManager = [
                  "homeConfigurations"
                  config.name
                ];
              }
              .${config.class};
          };
          mainModule = lib.mkOption {
            internal = true;
            visible = false;
            readOnly = true;
            type = lib.types.deferredModule;
            default = mainModule config den.ctx.home "home";
          };
        };
      }
    );

  mainModule =
    from: intent: name:
    let
      asp = intent { ${name} = from; };
    in
    den.lib.aspects.resolve (from.class) [ ] asp;
in
{
  inherit hostsOption homesOption;
}
