# constantHandler: Handles <arg-name> effects — resumes with context values for parametric aspects.
# ctxSeenHandler: Handles ctx-seen — dedup tracking for context stages.
# State reads: seen | State writes: seen
{
  lib,
  den,
  ...
}:
let
  # Build handler set from context.
  # Each key in ctx becomes a handler that resumes with the value.
  # Also installs "available-args" which returns the set of resolvable arg names.
  # Used by keepChild to skip parametric includes whose args aren't in scope.
  constantHandler =
    ctx:
    builtins.mapAttrs (
      _: value:
      { param, state }:
      {
        resume = value;
        inherit state;
      }
    ) ctx
    // {
      "available-args" =
        { param, state }:
        {
          # Merge with any outer available-args (from parent scopes).
          resume = (if param == { } then { } else param) // ctx;
          inherit state;
        };
    };

  # Dedup handler. Tracks seen keys in state.seen.
  ctxSeenHandler = {
    "ctx-seen" =
      { param, state }:
      let
        isFirst = !((state.seen or { }) ? ${param});
      in
      {
        resume = { inherit isFirst; };
        state = state // {
          seen = (state.seen or { }) // {
            ${param} = true;
          };
        };
      };
  };

in
{
  inherit
    constantHandler
    ctxSeenHandler
    ;
}
