{ den, lib, ... }:
let
  asIs = _: lib.id;
  upTo = f: builtins.intersectAttrs (lib.functionArgs f);

  take.unused = _unused: used: used;

  take.exactly = take den.lib.canTake.exactly asIs;
  take.atLeast = take den.lib.canTake.atLeast asIs;
  take.upTo = take den.lib.canTake.upTo upTo;

  take.__functor =
    _: canTake: argAdapter: fn: args:
    let
      ctx = argAdapter fn args;
    in
    if canTake ctx fn then fn ctx else { };
in
take
