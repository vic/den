# This example implements an aspect "routing" pattern.
#
# Unlike `den.default` which is `parametric.atLeast` we use `parametric.exactly` here
# to be more strict and prevent multiple values inclusion.
#
# Be sure to read: https://vic.github.io/den/dependencies.html
# See usage at: defaults.nix, alice.nix, igloo.nix
#
{ den, eg, ... }:
{
  # Usage: `den.default.includes [ eg.routes ]`
  eg.routes =
    let
      inherit (den.lib) parametric;

      # eg, `<user>._.<host>` and `<host>._.<user>`
      mutual = from: to: den.aspects.${from.aspect}._.${to.aspect} or { };

      routes =
        { host, user, ... }@ctx:
        {
          __functor = parametric ctx;
          includes = [
            (mutual user host)
            (mutual host user)
          ];
        };
    in
    routes;
}
