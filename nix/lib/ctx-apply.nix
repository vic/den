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
  # Structural keys that ctxApply always forwards.
  structuralKeys = [
    "name"
    "description"
    "meta"
    "includes"
    "provides"
    "into"
    "__functor"
    "__functionArgs"
    "__ctx"
    "_module"
  ];

  ctxApply =
    self: ctx:
    let
      meta = self.meta or { };
      # Preserve class keys (nixos, homeManager, funny, etc.) from the
      # ctx node definition — these are emitted by compileStatic.
      classAttrs = builtins.removeAttrs self structuralKeys;
    in
    classAttrs
    // {
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
