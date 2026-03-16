{ lib, den, ... }:
let
  # an aspect producing only owned configs
  owned = (lib.flip builtins.removeAttrs) [
    "includes"
    "__functor"
  ];

  # only static includes from an aspect.
  statics =
    aspect:
    aspect
    // {
      __functor =
        self:
        { class, aspect-chain }:
        {
          includes = map (applyStatics { inherit class aspect-chain; }) (self.includes or [ ]);
        };
    };

  applyStatics =
    ctx: f:
    if !lib.isFunction f then
      f
    else if isStatic f && isCtxStatic ctx then
      f ctx
    else
      { };

  isStatic = den.lib.canTake.atLeast {
    class = "";
    aspect-chain = [ ];
  };
  isCtxStatic = (lib.flip den.lib.canTake.exactly) ({ class, aspect-chain }: class aspect-chain);

in
{
  __functor = _: statics;
  inherit isCtxStatic owned statics;
}
