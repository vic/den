{ lib, den, ... }:
let
  owned = (lib.flip builtins.removeAttrs) [
    "includes"
    "__functor"
    "__functionArgs"
  ];

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

  applyStatics = ctx: f: if lib.isFunction f then den.lib.take.atLeast f ctx else f;

  isCtxStatic = ctx: ctx ? class || ctx ? aspect-chain;

in
{
  __functor = _: statics;
  inherit isCtxStatic owned statics;
}
