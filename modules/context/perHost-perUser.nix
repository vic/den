{
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (config.den.lib) take parametric;
  fixed = ctx: aspect: parametric.fixedTo ctx { includes = [ aspect ]; };
  perHost = aspect: { includes = [ (take.exactly ({ host }@ctx: fixed ctx aspect)) ]; };
  perUser = aspect: { includes = [ (take.exactly ({ host, user }@ctx: fixed ctx aspect)) ]; };
  perHome = aspect: { includes = [ (take.exactly ({ home }@ctx: fixed ctx aspect)) ]; };
in
{
  den.lib = { inherit perHome perUser perHost; };
}
