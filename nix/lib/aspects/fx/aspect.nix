{
  lib,
  den,
  fx,
  ...
}:
let
  # Translate an aspect into an effectful computation.
  #
  # Three cases:
  # 1. Plain attrset → fx.pure (no resolution needed)
  # 2. Empty functionArgs → factory function, apply with full ctx
  # 3. Destructured args → fx.bind.fn sends per-arg effects
  wrapAspect =
    ctx: aspect:
    if !lib.isFunction aspect then
      fx.pure aspect
    else if lib.functionArgs aspect == { } then
      fx.pure (aspect ctx)
    else
      fx.bind.fn { } aspect;
in
{
  inherit wrapAspect;
}
