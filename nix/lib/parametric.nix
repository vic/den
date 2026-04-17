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

  # Extract the aspect's class keys (nixos, darwin, etc.) without structural keys.
  # These must be emitted as a child include so the fx pipeline picks them up
  # via compileStatic → emit-class.
  structuralKeys = [
    "includes"
    "provides"
    "into"
    "__functor"
    "__functionArgs"
    "__ctx"
  ];
  owned = aspect: builtins.removeAttrs aspect structuralKeys;

  # Bind context values to an aspect for the fx pipeline.
  # Tags the result with __ctx so the pipeline can install scoped handlers
  # that provide the context values to nested parametric includes.
  # The owned class keys are emitted as a child include.
  bindCtx =
    takeFn: attrs: aspect:
    withIdentity aspect {
      __ctx = attrs;
      includes = [ (owned aspect) ] ++ applyCtxToIncludes takeFn attrs (aspect.includes or [ ]);
    };

  parametric.fixedTo.__functor = _: attrs: bindCtx take.atLeast attrs;
  parametric.fixedTo.exactly = attrs: bindCtx take.exactly attrs;
  parametric.fixedTo.atLeast = attrs: bindCtx take.atLeast attrs;
  parametric.fixedTo.upTo = attrs: bindCtx take.upTo attrs;

  parametric.atLeast = aspect: ctx: bindCtx take.atLeast ctx aspect;

  parametric.exactly = aspect: ctx: bindCtx take.exactly ctx aspect;

  parametric.expands = attrs: aspect: bindCtx take.atLeast attrs aspect;

  parametric.withIdentity = withIdentity;

  # Make parametric callable: den.lib.parametric aspect is sugar for
  # wrapping an aspect so it can be called with context later.
  # Returns a partially applied function: (parametric aspect) ctx → result
  parametric.__functor = _: parametric.atLeast;

in
parametric
