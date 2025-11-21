{
  lib,
  inputs,
  config,
  ...
}:
let
  den.lib = inputs.target.lib { inherit lib inputs config; };

  inherit (den.lib) parametric canTake;

  aspect-example = parametric.atLeast {
    nixos.foo = 99;
    includes = [
      { nixos.static = 100; }
      (
        { host, ... }:
        {
          nixos.host = host;
        }
      )
      (
        { host, user, ... }:
        {
          nixos.host-user = [
            host
            user
          ];
        }
      )
      (
        {
          OS,
          user,
          host,
          ...
        }:
        {
          nixos.os-user-host = [
            OS
            user
            host
          ];
        }
      )
      (
        { user, ... }:
        {
          nixos.user = user;
        }
      )
      (
        { user, ... }@ctx:
        if canTake.exactly ctx ({ user }: user) then
          {
            nixos.user-only = user;
          }
        else
          { nixos.user-only = false; }
      )
      (
        { home, ... }:
        {
          nixos.home = home;
        }
      )
      (_any: {
        nixos.any = 10;
      })
    ];
  };

  flake.tests."test functor applied with empty attrs" = {
    expr = (aspect-example { });
    expected = {
      includes = [
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with host only" = {
    expr = (
      aspect-example {
        host = 2;
      }
    );
    expected = {
      includes = [
        { nixos.host = 2; } # host
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with home only" = {
    expr = (
      aspect-example {
        home = 2;
      }
    );
    expected = {
      includes = [
        { nixos.home = 2; } # home
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with home and unknown" = {
    expr = (
      aspect-example {
        home = 2;
        unknown = 1;
      }
    );
    expected = {
      includes = [
        { nixos.home = 2; }
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with user only" = {
    expr = (
      aspect-example {
        user = 2;
      }
    );
    expected = {
      includes = [
        { nixos.user = 2; } # user
        { nixos.user-only = 2; } # user-only
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with user and host" = {
    expr = (
      aspect-example {
        user = 2;
        host = 1;
      }
    );
    expected = {
      includes = [
        { nixos.host = 1; }
        {
          nixos.host-user = [
            1
            2
          ];
        }
        { nixos.user = 2; }
        { nixos.user-only = false; }
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with host/user/OS" = {
    expr = (
      aspect-example {
        OS = 0;
        user = 2;
        host = 1;
      }
    );
    expected = {
      includes = [
        { nixos.host = 1; }
        {
          nixos.host-user = [
            1
            2
          ];
        }
        {
          nixos.os-user-host = [
            0
            2
            1
          ];
        }
        { nixos.user = 2; }
        { nixos.user-only = false; }
        { nixos.any = 10; }
      ];
    };
  };

in
{
  inherit flake;
}
