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

      os-from-user =
        {
          user,
          host,
          # deadnix: skip
          OS,
          # deadnix: skip
          fromUser,
        }:
        parametric { inherit user host; } (mutual user host);

      hm-from-host =
        {
          user,
          host,
          # deadnix: skip
          HM,
          # deadnix: skip
          fromHost,
        }:
        parametric { inherit user host; } (mutual host user);

      mutual = from: to: {
        includes = [
          # eg, `<user>._.<host>` and `<host>._.<user>`
          (den.aspects.${from.aspect}._.${to.aspect} or { })
        ];
      };

    in
    {
      __functor = parametric.exactly;
      includes = [
        os-from-user
        hm-from-host
      ];
    };
}
