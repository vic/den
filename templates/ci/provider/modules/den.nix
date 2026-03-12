{
  inputs,
  den,
  lib,
  ...
}:
{
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "provider" true)
  ];

  provider.tools._.dev._.editors = {
    description = "Editor configurations from provider flake";
    nixos.programs.vim.enable = true;
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vim ];
      };
  };

  provider.tools._.dev._.host-stamp = den.lib.parametric {
    includes = [
      (
        { host, ... }:
        {
          nixos.environment.sessionVariables.PROVIDER_HOST = host.name;
        }
      )
    ];
  };

  provider.tools._.dev._.user-stamp = den.lib.parametric.exactly {
    includes = [
      (
        { host, user, ... }:
        {
          nixos.users.users.${user.userName}.description = "user-of-${host.name}";
        }
      )
    ];
  };

  # A ctx entry shared to consumers — provides a self-provider function.
  provider.ctx.simple._.simple = _: { funny.names = [ "from-provider-ctx" ]; };

  # A schema entry that can be shared to consumers.
  provider.schema.entity = {
    options.names = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    config.names = lib.mkDefault [ "provider-entity-schema" ];
  };
}
