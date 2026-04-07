{ lib, den, ... }:
let
  inherit (den.lib) take;
  inherit (den.lib.statics) owned statics isCtxStatic;

  parametric.applyIncludes =
    takeFn: aspect:
    aspect
    // {
      __functor = self: ctx: {
        includes = (builtins.filter (x: x != { })) (map (fn: takeFn fn ctx) (self.includes or [ ]));
      };
    };

  mapIncludes =
    branch: leaf: aspect:
    aspect
    // {
      includes = map (
        include: if include ? includes && !include ? __functor then branch include else leaf include
      ) (aspect.includes or [ ]);
    };

  parametric.atLeast = parametric.applyIncludes take.atLeast;

  parametric.exactly = parametric.applyIncludes take.exactly;

  parametric.expands =
    attrs: parametric.withOwn (aspect: ctx: parametric.atLeast aspect (ctx // attrs));

  deepRecurse =
    include: branch: leaf: aspect:
    aspect
    // {
      __functor =
        self:
        { class, aspect-chain }:
        {
          includes = [
            (include self { inherit class aspect-chain; })
            (mapIncludes (deepRecurse include branch leaf) leaf (branch aspect))
          ];
        };
    };

  includeOwnedAndStatics = self: staticCtx: {
    includes = [
      (owned self)
      (statics self staticCtx)
    ];
  };

  includeNothing = (_: _: { });

  parametric.deepOwned = functor: deepRecurse includeOwnedAndStatics functor lib.id;
  parametric.deepParametrics = functor: deepRecurse includeNothing lib.id functor;

  parametric.fixedTo.__functor = _: attrs: parametric.deepOwned (lib.flip parametric.atLeast attrs);
  parametric.fixedTo.exactly = attrs: parametric.deepParametrics (lib.flip take.exactly attrs);
  parametric.fixedTo.atLeast = attrs: parametric.deepParametrics (lib.flip take.atLeast attrs);
  parametric.fixedTo.upTo = attrs: parametric.deepParametrics (lib.flip take.upTo attrs);

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
