{ den, lib, ... }:
let
  take.unused = _unused: used: used;
  take.exactly = take (_fn: ctx: ctx) den.lib.canTake.exactly;
  take.atLeast = take (_fn: ctx: ctx) den.lib.canTake.atLeast;
  take.upTo = take (fn: fn |> lib.functionsArgs |> builtins.intersectAttrs) den.lib.canTake.upTo;
  take.__functor =
    _: takes: adapter: fn: ctx:
    if takes ctx fn then fn (adapter fn ctx) else { };
in
take
