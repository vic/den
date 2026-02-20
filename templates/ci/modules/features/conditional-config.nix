{ denTest, ... }:
{
  flake.tests.conditional-config = {

    test-conditional-hm-by-user-and-host = denTest (
      {
        den,
        lib,
        tuxHm,
        pinguHm,
        ...
      }:
      let
        git-for-linux-only =
          { user, host, ... }:
          if user.userName == "tux" && !lib.hasSuffix "darwin" host.system then
            { homeManager.programs.git.enable = true; }
          else
            { };
      in
      {
        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };
        den.default.homeManager.home.stateVersion = "25.11";
        den.aspects.tux.includes = [ git-for-linux-only ];

        expr = [
          tuxHm.programs.git.enable
          pinguHm.programs.git.enable
        ];
        expected = [
          true
          false
        ];
      }
    );

    test-conditional-os-by-user-system = denTest (
      {
        den,
        lib,
        igloo,
        iceberg,
        ...
      }:
      let
        tmux-on-linux =
          { user, host, ... }:
          if user.userName == "tux" && !lib.hasSuffix "darwin" host.system then
            { nixos.programs.tmux.enable = true; }
          else
            { };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.x86_64-linux.iceberg.users.tux = { };
        den.aspects.tux.includes = [ tmux-on-linux ];

        expr = [
          igloo.programs.tmux.enable
          iceberg.programs.tmux.enable
        ];
        expected = [
          true
          true
        ];
      }
    );

    test-custom-nixos-module-import = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      let
        peopleModule = {
          options.people = lib.mkOption { type = lib.types.listOf lib.types.str; };
        };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.default.nixos.imports = [ peopleModule ];
        den.default.includes = [
          (
            { user, ... }:
            {
              nixos.people = [ user.userName ];
            }
          )
        ];

        expr = igloo.people;
        expected = [ "tux" ];
      }
    );

    test-static-aspect-in-default = denTest (
      { den, igloo, ... }:
      let
        set-timezone = {
          nixos.time.timeZone = "UTC";
        };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.default.includes = [ set-timezone ];

        expr = igloo.time.timeZone;
        expected = "UTC";
      }
    );

  };
}
