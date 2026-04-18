{ den, lib, ... }:
let
  warn = msg: v: lib.warn "den.lib.take: ${msg}" v;

  take.unused = _unused: used: used;

  take.exactly = fn: warn "take.exactly is deprecated" fn;
  take.atLeast = fn: warn "take.atLeast is deprecated" fn;
  take.upTo = fn: warn "take.upTo is deprecated" fn;

  take.__functor =
    _: _canTake: _argAdapter: fn:
    warn "take is deprecated" fn;
in
take
