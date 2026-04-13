{
  lib,
  den,
  fx,
  ...
}:
let
  # Build handler set from parametric context.
  # Each key in ctx becomes a handler that resumes with the value.
  parametricHandler =
    ctx:
    builtins.mapAttrs (
      _: value:
      { param, state }:
      {
        resume = value;
        inherit state;
      }
    ) ctx;

  # Handle class and aspect-chain effects.
  staticHandler =
    { class, aspect-chain }:
    {
      "class" =
        { param, state }:
        {
          resume = class;
          inherit state;
        };
      "aspect-chain" =
        { param, state }:
        {
          resume = aspect-chain;
          inherit state;
        };
    };

  # Merge parametric + static into a single handler set.
  contextHandlers =
    {
      ctx,
      class,
      aspect-chain,
    }:
    parametricHandler ctx // staticHandler { inherit class aspect-chain; };

  # Build diagnostic error for unhandled effect (missing context arg).
  missingArgError =
    { ctx, aspectName }:
    effectName:
    let
      available = builtins.attrNames ctx ++ [
        "class"
        "aspect-chain"
      ];
    in
    throw "aspect '${aspectName}' requires '${effectName}' but context only provides: ${toString available}";
in
{
  inherit
    parametricHandler
    staticHandler
    contextHandlers
    missingArgError
    ;
}
