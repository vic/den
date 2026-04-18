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
  constantHandler =
    ctx:
    builtins.mapAttrs (
      _: value:
      { param, state }:
      {
        resume = value;
        inherit state;
      }
    ) ctx;

  # Scope-args handlers: push/pop availableArgs in state.
  # These effects rotate through scope.run to the pipeline root,
  # maintaining a stack so nested scopes correctly track which
  # context arg names are resolvable at each level.
  scopeArgsHandler = {
    "push-scope-args" =
      { param, state }:
      {
        resume = null;
        state = state // {
          # Store just keys (true values) to avoid deepSeq forcing NixOS configs.
          availableArgs = (state.availableArgs or { }) // builtins.mapAttrs (_: _: true) param;
          _argsStack = (state._argsStack or [ ]) ++ [ (state.availableArgs or { }) ];
        };
      };
    "pop-scope-args" =
      { param, state }:
      let
        stack = state._argsStack or [ ];
      in
      {
        resume = null;
        state = state // {
          availableArgs = if stack == [ ] then { } else lib.last stack;
          _argsStack = if stack == [ ] then [ ] else lib.init stack;
        };
      };
    "probe-arg" =
      { param, state }:
      {
        resume = (state.availableArgs or { }) ? ${param};
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
    scopeArgsHandler
    ;
}
