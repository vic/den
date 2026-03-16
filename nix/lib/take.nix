{ den, ... }:
let
  take.unused = _unused: used: used;
  take.exactly = take den.lib.canTake.exactly;
  take.atLeast = take den.lib.canTake.atLeast;
  take.__functor =
    _: takes: fn: ctx:
    if takes ctx fn then fn ctx else { };
in
take
