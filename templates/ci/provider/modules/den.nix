{ inputs, den, ... }:
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
}
