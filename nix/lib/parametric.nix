{ lib, den, ... }:
let
  inherit (den.lib) take recursiveFunctor;
  inherit (den.lib.statics) owned statics isCtxStatic;

  parametric.applyIncludes =
    takeFn: aspect:
    aspect
    // {
      __functor = self: ctx: {
        includes = (builtins.filter (x: x != { })) (map (fn: takeFn fn ctx) (self.includes or [ ]));
      };
    };

  deepRecurse =
    functor: ctx: provided:
    provided
    // {
      includes = map (
        include: if include ? includes then parametric.deep functor ctx include else include
      ) (provided.includes or [ ]);
    };

  parametric.atLeast = parametric.applyIncludes take.atLeast;

  parametric.exactly = parametric.applyIncludes take.exactly;

  parametric.expands =
    attrs: parametric.withOwn (aspect: ctx: parametric.atLeast aspect (ctx // attrs));

  parametric.deep =
    functor: attrs: aspect:
    aspect
    // {
      __functor =
        self:
        { class, aspect-chain }:
        {
          includes = [
            (owned self)
            (statics self { inherit class aspect-chain; })
            (deepRecurse functor attrs (functor self attrs))
          ];
        };
    };

  parametric.fixedTo = parametric.deep parametric.atLeast // {
    atLeast = recursiveFunctor (lib.flip take.atLeast);
    exactly = recursiveFunctor (lib.flip take.exactly);
    upTo = recursiveFunctor (lib.flip take.upTo);
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
