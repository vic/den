{
  inputs,
  config,
  lib,
  den,
  ...
}@top:
let
  hostsOption = lib.mkOption {
    description = "den hosts definition";
    default = { };
    defaultText = lib.literalExpression "{ }";
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
          aspect = lib.mkOption {
            description = "Aspect that configures this host.";
            type = lib.types.raw; # no merging
            defaultText = "den.aspects.<name>";
            default = den.aspects.${config.name};
          };
          description = strOpt "host description" "${config.class}.${config.hostName}@${config.system}";
          users = lib.mkOption {
            description = "user accounts";
            default = { };
            defaultText = lib.literalExpression "{ }";
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
            defaultText = lib.literalExpression "inputs.nixpkgs.lib.nixosSystem";
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
            defaultText = lib.literalExpression ''[  "nixosConfigurations" hostName ]'';
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
            defaultText = "den.lib.aspects.resolve config.class config.resolved";
            default = den.lib.aspects.resolve config.class config.resolved;
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
            defaultText = lib.literalExpression ''[ "user" ]'';
            default = [ "user" ];
          };
          aspect = lib.mkOption {
            description = "Aspect that configures this user.";
            type = lib.types.raw; # no merging
            defaultText = "den.aspects.<name>";
            default = den.aspects.${config.name};
          };
          host = lib.mkOption {
            default = host;
            defaultText = lib.literalExpression "host";
          };
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
        parts = builtins.split "@" name;
        nameWithHost = builtins.length parts > 1;
        userName = lib.head parts;
        hostName = if nameWithHost then lib.last parts else null;
        hostByName = den.hosts.${system}.${hostName} or null;
        userByName = hostByName.users.${userName} or null;

        homeManagerConfiguration =
          if nameWithHost && hostByName != null then
            { pkgs, modules }:
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs modules;
              extraSpecialArgs.osConfig = lib.attrByPath (
                [ "flake" ] ++ hostByName.intoAttr ++ [ "config" ]
              ) null top.config;
            }
          else
            inputs.home-manager.lib.homeManagerConfiguration;
      in
      {
        freeformType = lib.types.attrsOf lib.types.anything;
        imports = [ den.schema.home ];
        config._module.args.home = config;
        config._module.args.host = hostByName;
        config._module.args.user = userByName;
        options = {
          name = strOpt "home configuration name" userName;
          userName = strOpt "user account name" userName;
          hostName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = hostName;
            description = "host name (null for unbound standalone homes)";
          };
          user = lib.mkOption {
            default = userByName;
            defaultText = lib.literalExpression "user";
          };
          host = lib.mkOption {
            default = hostByName;
            defaultText = lib.literalExpression "host";
          };
          system = strOpt "platform system" system;
          class = strOpt "home management nix class" "homeManager";
          aspect = lib.mkOption {
            description = "Aspect that configures this home.";
            type = lib.types.raw; # no merging
            defaultText = "den.aspects.<name>";
            default = den.aspects.${config.name};
          };
          description = strOpt "home description" "home.${config.name}@${config.system}";
          pkgs = lib.mkOption {
            description = ''
              nixpkgs instance used to build the home configuration.
            '';
            example = lib.literalExpression ''inputs.nixpkgs.legacyPackages.''${home.system}'';
            type = lib.types.raw;
            defaultText = lib.literalExpression ''inputs.nixpkgs.legacyPackages.''${home.system}'';
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
            defaultText = lib.literalExpression "inputs.home-manager.lib.homeManagerConfiguration";
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
            defaultText = lib.literalExpression ''[  "homeConfigurations" userName ]'';
            default =
              {
                homeManager = [
                  "homeConfigurations"
                  name
                ];
              }
              .${config.class};
          };
          mainModule = lib.mkOption {
            internal = true;
            visible = false;
            readOnly = true;
            type = lib.types.deferredModule;
            defaultText = "den.lib.aspects.resolve config.class config.resolved";
            default = den.lib.aspects.resolve config.class config.resolved;
          };
        };
      }
    );
in
{
  inherit hostsOption homesOption;
}
