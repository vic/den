{ lib, inputs, ... }:
let
  takes = import "${inputs.target}/nix/fn-can-take.nix" lib;

  flake.tests."test function with no named arguments can take anything" = {
    expr = takes { } (x: x);
    expected = true;
  };

  flake.tests."test function called with non attrs" = {
    expr = takes 22 ({ host }: [ host ]);
    expected = false;
  };

  flake.tests."test function missing required attr" = {
    expr = takes { } ({ host }: [ host ]);
    expected = false;
  };

  flake.tests."test function satisfied required attr" = {
    expr = takes {
      host = 1;
    } ({ host, ... }: [ host ]);
    expected = true;
  };

  flake.tests."test function missing second required attr" = {
    expr =
      takes
        {
          host = 1;
        }
        (
          { host, user }:
          [
            host
            user
          ]
        );
    expected = false;
  };

  flake.tests."test function optional second attr" = {
    expr =
      takes
        {
          host = 1;
          foo = 9;
        }
        (
          {
            host,
            user ? 0,
          }:
          [
            host
            user
          ]
        );
    expected = false;
  };

in
{
  inherit flake;
}
