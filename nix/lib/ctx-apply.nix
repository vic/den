{ lib, den, ... }:
_ctxNs:
# Transparent context bridge — tags aspect with __ctx for pipeline.
# The fx pipeline handles all context resolution:
#   - transitionHandler processes into transitions with scope.run constantHandler
#   - emitSelfProvide handles self-providers
#   - ctxSeenHandler handles dedup
#   - Root constantHandler provides host/user/etc from __ctx
#
# Cross-providers (parent.provides.${childKey}) are handled by the
# enhanced transitionHandler which includes them in child resolution.
self: ctx:
let
  inherit (den.lib) parametric;
  # Evaluate the context aspect eagerly to break the laziness cycle
  # between the module system and the pipeline. Without this, accessing
  # self.into etc. during pipeline resolution triggers circular eval.
  stripped = builtins.removeAttrs self [
    "_module"
    "__functor"
    "__functionArgs"
  ];
  classKeys = builtins.removeAttrs stripped [
    "name"
    "meta"
    "includes"
    "provides"
    "into"
    "description"
  ];
in
parametric.withIdentity self (
  classKeys
  // {
    __ctx = ctx;
    # Keep includes and into — the pipeline handles them.
    # into is needed for transitionHandler to process context transitions.
    inherit (self) includes;
  }
  // lib.optionalAttrs (self ? into) { inherit (self) into; }
  // lib.optionalAttrs (self ? provides) { inherit (self) provides; }
)
