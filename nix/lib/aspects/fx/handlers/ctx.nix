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
  # Also installs probe-arg: checks if an arg name is in this handler's ctx.
  # Used by keepChild to skip parametric includes whose args aren't resolvable.
  # Note: with deep handlers, inner scope's probe-arg shadows outer. This is
  # correct because inner scopes always have >= outer context (host ⊂ host+user).
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
      # Check own ctx AND pipeline-provided args (class, aspect-chain).
      # These are always available from root handlers but would be missed
      # if only checking the scoped ctx keys.
      "probe-arg" =
        { param, state }:
        {
          resume =
            ctx ? ${param}
            || builtins.elem param [
              "class"
              "aspect-chain"
            ];
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
