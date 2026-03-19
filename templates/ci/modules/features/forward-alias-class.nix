{ denTest, ... }:
{
  flake.tests.forward-alias-class = {

    test-home-alias-forwards-into-home-manager-root = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      let
        forwarded =
          { class, aspect-chain }:
          den._.forward {
            each = lib.singleton class;
            fromClass = _: "home";
            intoClass = _: "homeManager";
            intoPath = _: [ ];
            fromAspect = _: lib.head aspect-chain;
            adaptArgs =
              { config, ... }:
              {
                osConfig = config;
              };
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.nixos.networking.hostName = "storm";

        den.aspects.tux = {
          includes = [ forwarded ];
          home =
            { osConfig, ... }:
            {
              programs.fish.enable = true;
              home.keyboard.model = osConfig.networking.hostName;
            };
        };

        expr = {
          enable = igloo.home-manager.users.tux.programs.fish.enable;
          model = igloo.home-manager.users.tux.home.keyboard.model;
        };
        expected = {
          enable = true;
          model = "storm";
        };
      }
    );

    test-guarded-home-alias-forwards-into-home-manager-root = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      let
        forwarded =
          { class, aspect-chain }:
          den._.forward {
            each = lib.singleton class;
            fromClass = _: "home";
            intoClass = _: "homeManager";
            intoPath = _: [ ];
            fromAspect = _: lib.head aspect-chain;
            guard = { config, ... }: _: lib.mkIf config.programs.fish.enable;
            adaptArgs =
              { config, ... }:
              {
                osConfig = config;
              };
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.nixos.networking.hostName = "storm";
        den.aspects.tux.homeManager.programs.fish.enable = true;

        den.aspects.tux = {
          includes = [ forwarded ];
          home =
            { osConfig, ... }:
            {
              home.keyboard.model = osConfig.networking.hostName;
            };
        };

        expr = {
          enable = igloo.home-manager.users.tux.programs.fish.enable;
          model = igloo.home-manager.users.tux.home.keyboard.model;
        };
        expected = {
          enable = true;
          model = "storm";
        };
      }
    );

    test-hm-platforms-example = denTest (
      {
        den,
        lib,
        igloo,
        apple,
        ...
      }:
      let
        forwarded =
          { class, aspect-chain }:
          den._.forward {
            each = [
              "Linux"
              "Darwin"
            ];
            fromClass = platform: "hm${platform}";
            intoClass = _: "homeManager";
            intoPath = _: [ ];
            fromAspect = _: lib.head aspect-chain;
            guard = { pkgs, ... }: platform: lib.mkIf pkgs.stdenv."is${platform}";
            adaptArgs =
              { config, ... }:
              {
                osConfig = config;
              };
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.aarch64-darwin.apple.users.tux = { };

        den.aspects.tux = {
          includes = [ forwarded ];
          hmLinux.home.keyboard.model = "freedom";
          hmDarwin.home.keyboard.model = "closed";
        };

        expr = {
          linux = igloo.home-manager.users.tux.home.keyboard.model;
          darwin = apple.home-manager.users.tux.home.keyboard.model;
        };
        expected = {
          linux = "freedom";
          darwin = "closed";
        };
      }
    );

  };
}
