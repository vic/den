{ den, lib, ... }:
let
  asIs = _: lib.id;
  upTo = f: builtins.intersectAttrs (lib.functionArgs f);

  # Carry name from the function to its result when the result doesn't
  # already have one. This preserves aspect identity through take calls.
  carryAttrs =
    fn: result:
    if builtins.isAttrs result then
      result
      // lib.optionalAttrs ((fn.name or null) != null && !(result ? name)) { inherit (fn) name; }
    else
      result;

  take.unused = _unused: used: used;

  take.exactly = take den.lib.canTake.exactly asIs;
  take.atLeast = take den.lib.canTake.atLeast asIs;
  take.upTo = take den.lib.canTake.upTo upTo;

  take.__functor =
    _: canTake: argAdapter: fn: args:
    let
      ctx = argAdapter fn args;
    in
    if canTake ctx fn then carryAttrs fn (fn ctx) else { };
in
take
