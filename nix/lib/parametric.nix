{ lib, den, ... }:
let
  inherit (den.lib) take functor;
  inherit (den.lib.statics) owned statics isCtxStatic;

  fixedRecurse =
    ctx: provided:
    provided
    // {
      includes = map (include: if include ? includes then parametric.fixedTo ctx include else include) (
        provided.includes or [ ]
      );
    };

  parametric.atLeast = functor (lib.flip take.atLeast);

  parametric.exactly = functor (lib.flip take.exactly);

  parametric.expands =
    attrs: parametric.withOwn (aspect: ctx: parametric.atLeast aspect (ctx // attrs));

  parametric.fixedTo =
    attrs: aspect:
    aspect
    // {
      __functor =
        self:
        { class, aspect-chain }:
        {
          includes = [
            (owned self)
            (statics self { inherit class aspect-chain; })
            (fixedRecurse attrs (parametric.atLeast self attrs))
          ];
        };
    };

  parametric.withOwn =
    functor: aspect:
    aspect
    // {
      __functor = self: ctx: {
        includes =
          if isCtxStatic ctx then
            [
              (owned self)
              (statics self ctx)
            ]
          else
            [ (functor self ctx) ];
      };
    };

  parametric.__functor = _: parametric.withOwn parametric.atLeast;
in
parametric
