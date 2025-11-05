{ lib, inputs, ... }:
let
  __functor = import "${inputs.target}/nix/aspect-functor.nix" lib;

  tail = out: { includes = lib.drop 1 out.includes; };

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

  flake.tests."test provider function must be returned as is" =
    let
      provider =
        { class, aspect-chain }:
        [
          class
          aspect-chain
        ];
      x = tail (
        {
          inherit __functor;
          includes = [ provider ];
        }
          { }
      );
    in
    {
      expr = (builtins.elemAt x.includes 0) {
        class = "foo";
        aspect-chain = [ ];
      };
      expected = [
        "foo"
        [ ]
      ];
    };

  flake.tests."test functor first element is foo" = {
    expr =
      let
        first = builtins.elemAt (aspect-example { }).includes 0;
      in
      (first {
        class = "nixos";
        aspect-chain = [ ];
      });
    expected = {
      nixos.foo = 99;
    };
  };

  flake.tests."test functor applied with empty attrs" = {
    expr = tail (aspect-example { });
    expected = {
      includes = [
        { nixos.static = 100; }
        { } # host
        { } # host user
        { } # user
        { } # user-only
        { } # home
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with host only" = {
    expr = tail (aspect-example {
      host = 2;
    });
    expected = {
      includes = [
        { nixos.static = 100; }
        { nixos.host = 2; } # host
        { } # host user
        { } # user
        { } # user-only
        { } # home
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with home only" = {
    expr = tail (aspect-example {
      home = 2;
    });
    expected = {
      includes = [
        { nixos.static = 100; }
        { } # host
        { } # host user
        { } # user
        { } # user-only
        { nixos.home = 2; } # home
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with home and unknown" = {
    expr = tail (aspect-example {
      home = 2;
      unknown = 1;
    });
    expected = {
      includes = [
        { nixos.static = 100; }
        { } # host
        { } # host user
        { } # user
        { } # user-only
        { } # home
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with user only" = {
    expr = tail (aspect-example {
      user = 2;
    });
    expected = {
      includes = [
        { nixos.static = 100; }
        { } # host
        { } # host user
        { nixos.user = 2; } # user
        { nixos.user-only = 2; } # user-only
        { } # home
        { nixos.any = 10; }
      ];
    };
  };

  flake.tests."test functor applied with user and host" = {
    expr = tail (aspect-example {
      user = 2;
      host = 1;
    });
    expected = {
      includes = [
        { nixos.static = 100; }
        { } # host
        {
          nixos.host-user = [
            1
            2
          ];
        } # host user
        { } # user
        { } # user-only
        { } # home
        { nixos.any = 10; }
      ];
    };
  };

in
{
  inherit flake;
}
