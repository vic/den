{ lib, den, ... }:
let
  warn = msg: v: lib.warn "den.lib.parametric: ${msg}" v;

  parametric.fixedTo.__functor =
    _: _ctx: aspect:
    warn "fixedTo is deprecated — the fx pipeline provides context via effects" aspect;
  parametric.fixedTo.exactly = _ctx: aspect: warn "fixedTo.exactly is deprecated" aspect;
  parametric.fixedTo.atLeast = _ctx: aspect: warn "fixedTo.atLeast is deprecated" aspect;
  parametric.fixedTo.upTo = _ctx: aspect: warn "fixedTo.upTo is deprecated" aspect;

  parametric.atLeast = aspect: warn "atLeast is deprecated — use plain attrsets" aspect;
  parametric.exactly = aspect: warn "exactly is deprecated — use plain attrsets" aspect;
  parametric.expands = _attrs: aspect: warn "expands is deprecated" aspect;

  parametric.__functor = _: parametric.atLeast;
in
parametric
