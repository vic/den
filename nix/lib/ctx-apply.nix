# ctxApply — the __functor of ctx nodes.
#
# Called as: den.ctx.host { host = config; }
# Returns an aspect-shaped attrset preserving into/provides for
# the fx pipeline's transitionHandler and emitSelfProvide to handle.
#
# The __ctx field carries the initial context value to the pipeline
# entry point (fxResolveTree extracts it for defaultHandlers).
{ lib, den, ... }:
_ctxNs:
let
  ctxApply =
    self: ctx:
    let
      meta = self.meta or { };
    in
    {
      name = self.name or "<anon>";
      meta = {
        handleWith = meta.handleWith or null;
        excludes = meta.excludes or [ ];
        provider = meta.provider or [ ];
      };
      # Preserve for the pipeline to handle natively:
      # - into: transitionHandler evaluates with currentCtx, recurses into target ctx nodes
      # - provides: emitSelfProvide handles provides.${self.name}
      # - includes: emitIncludes processes child aspects
      into = self.into or (_: { });
      provides = self.provides or { };
      includes = self.includes or [ ];
      # Carry context to the pipeline entry point.
      __ctx = ctx;
    };
in
ctxApply
