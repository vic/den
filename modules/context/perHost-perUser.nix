{
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (config.den.lib) take parametric;
  fixed = ctx: aspect: parametric.fixedTo ctx { includes = [ aspect ]; };
  perHost = aspect: take.exactly ({ host }@ctx: fixed ctx aspect);
  perUser = aspect: take.exactly ({ host, user }@ctx: fixed ctx aspect);
in
{
  den.lib = { inherit perUser perHost; };
}
