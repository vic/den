# "Just Give 'Em One of These" -  Moe Szyslak
# A __functor that applies context to parametric includes (functions) and recurses into other included aspects
{ lib, ... }:
let
  recursiveApply =
    apply: ctx: include:
    if include ? includes then recursiveFunctor apply include ctx else apply ctx include;
  recursiveFunctor =
    apply: aspect:
    aspect
    // {
      __functor = self: ctx: {
        includes =
          self.includes or [ ]
          |> builtins.filter lib.isFunction
          |> map (recursiveApply apply ctx)
          |> builtins.filter (x: x != { });
      };
    };
in
recursiveFunctor
