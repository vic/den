{
  lib,
  inputs,
  config,
  ...
}:
let
  __functor = (inputs.target.lib { inherit lib inputs config; }).parametric true;

  aspect-example = {
    inherit __functor;
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
        { host, user }:
        {
          nixos.host-user = [
            host
            user
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
        if builtins.length (builtins.attrNames ctx) == 1 then
          {
            nixos.user-only = user;
          }
        else
          { }
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
        {
          nixos.host-user = [
            1
            2
          ];
        } # host user
        { nixos.any = 10; }
      ];
    };
  };

in
{
  inherit flake;
}
