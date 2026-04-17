{ lib, den, ... }:
let
  inherit (den.lib) take canTake;

  # Preserve aspect identity through functor evaluation.
  # Carries name and typed meta options so adapters and provenance
  # survive, without leaking freeform user meta to child results.
  withIdentity =
    self: extra:
    let
      meta = self.meta or { };
    in
    {
      name = self.name or "<anon>";
      meta = {
        adapter = meta.adapter or null;
        handleWith = meta.handleWith or null;
        excludes = meta.excludes or [ ];
        provider = meta.provider or [ ];
      };
    }
    // extra;

  # Copy fn's meta onto a materialized functor result. Preserves
  # meta.provider so provider sub-aspects keep their full aspectPath
  # (e.g. ["foo","sub"]) after the user fn is invoked and returns a
  # raw attrset that would otherwise drop it.
  carryMeta =
    fn: result:
    if builtins.isAttrs result && fn ? meta && !(result ? meta) then
      result // { inherit (fn) meta; }
    else
      result;

  # Eagerly apply context to includes that accept it.
  # Includes whose required args aren't satisfied pass through unchanged
  # for the fx pipeline to handle later.
  applyCtxToIncludes =
    takeFn: attrs: includes:
    builtins.filter (x: x != { }) (
      map (i: if canTake.upTo attrs i then carryMeta i (takeFn i attrs) else i) (includes)
    );

  parametric.fixedTo.__functor =
    _: attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.atLeast attrs (aspect.includes or [ ]);
    };
  parametric.fixedTo.exactly =
    attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.exactly attrs (aspect.includes or [ ]);
    };
  parametric.fixedTo.atLeast =
    attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.atLeast attrs (aspect.includes or [ ]);
    };
  parametric.fixedTo.upTo =
    attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.upTo attrs (aspect.includes or [ ]);
    };

  parametric.atLeast =
    aspect: ctx:
    withIdentity aspect {
      includes = applyCtxToIncludes take.atLeast ctx (aspect.includes or [ ]);
    };

  parametric.exactly =
    aspect: ctx:
    withIdentity aspect {
      includes = applyCtxToIncludes take.exactly ctx (aspect.includes or [ ]);
    };

  parametric.expands =
    attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.atLeast attrs (aspect.includes or [ ]);
    };

  parametric.withIdentity = withIdentity;

in
parametric
