{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (config) den;

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
        imports = [ den.base.host ];
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
            type = lib.types.attrsOf userType;
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
            type = lib.types.unspecified;
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
            example = lib.literalExpression ''"nixosConfigurations"'';
            type = lib.types.str;
            default =
              {
                nixos = "nixosConfigurations";
                darwin = "darwinConfigurations";
                systemManager = "systemConfigs";
              }
              .${config.class};
          };
          mainModule = lib.mkOption {
            internal = true;
            visible = false;
            readOnly = true;
            type = lib.types.deferredModule;
            default = mainModule config "OS" "host";
          };
        };
      }
    );

  userType = lib.types.submodule (
    { name, config, ... }:
    {
      freeformType = lib.types.attrsOf lib.types.anything;
      imports = [ den.base.user ];
      config._module.args.user = config;
      options = {
        name = strOpt "user configuration name" name;
        userName = strOpt "user account name" config.name;
        class = strOpt "home management nix class" "homeManager";
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
      {
        freeformType = lib.types.attrsOf lib.types.anything;
        imports = [ den.base.home ];
        config._module.args.home = config;
        options = {
          name = strOpt "home configuration name" name;
          userName = strOpt "user account name" config.name;
          system = strOpt "platform system" system;
          class = strOpt "home management nix class" "homeManager";
          aspect = strOpt "main aspect name" config.name;
          description = strOpt "home description" "home.${config.userName}@${config.system}";
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
            type = lib.types.unspecified;
            default =
              {
                homeManager = inputs.home-manager.lib.homeManagerConfiguration;
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
            example = lib.literalExpression ''"homeConfigurations"'';
            type = lib.types.str;
            default =
              {
                homeManager = "homeConfigurations";
              }
              .${config.class};
          };
          mainModule = lib.mkOption {
            internal = true;
            visible = false;
            readOnly = true;
            type = lib.types.deferredModule;
            default = mainModule config "HM" "home";
          };
        };
      }
    );

  mainModule =
    from: intent: name:
    let
      asp = den.aspects.${from.aspect};
      ctx = {
        ${intent} = asp;
        ${name} = from;
      };
      mod = (asp ctx).resolve { inherit (from) class; };
    in
    mod;
in
{
  inherit hostsOption homesOption;
}
