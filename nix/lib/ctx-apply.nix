{ lib, den, ... }:
_ctxNs:
# Transparent context bridge.
# Tags the context aspect with __ctx (the entity's context values)
# and lets the fx pipeline handle all resolution:
#   - transitionHandler processes into transitions with scoped constantHandler
#   - emitSelfProvide handles self-providers
#   - ctxSeenHandler handles dedup
#   - constantHandler provides host/user/etc from __ctx
self: ctx:
self // { __ctx = ctx; }
