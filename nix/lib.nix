{
  inputs,
  lib,
  config,
  ...
}:
let

  # "Just Give 'Em One of These" -  Moe Szyslak
  # A __functor that applies context to parametric includes (functions)
  funk =
    apply: aspect:
    aspect
    // {
      __functor = self: ctx: {
        includes = builtins.filter (x: x != { }) (map (apply ctx) (builtins.filter isFn self.includes));
      };
    };

  isFn = f: (builtins.isFunction f) || (builtins.isAttrs f && f ? __functor);
  canTake = import ./fn-can-take.nix lib;

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
          includes = map (applyStatics { inherit class aspect-chain; }) self.includes;
        };
    };

  applyStatics =
    ctx: f:
    if !isFn f then
      f
    else if isStatic f && isCtxStatic ctx then
      f ctx
    else
      { };

  isStatic = canTake.atLeast {
    class = "";
    aspect-chain = [ ];
  };
  isCtxStatic = (lib.flip canTake.exactly) ({ class, aspect-chain }: class aspect-chain);

  take.unused = _unused: used: used;
  take.exactly = take canTake.exactly;
  take.atLeast = take canTake.atLeast;
  take.__functor =
    _: takes: fn: ctx:
    if takes ctx fn then fn ctx else { };

  parametric.atLeast = funk (lib.flip take.atLeast);
  parametric.exactly = funk (lib.flip take.exactly);
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
            (parametric.atLeast self attrs)
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

  aspects = inputs.flake-aspects.lib lib;

  __findFile = import ./den-brackets.nix { inherit lib config; };

  den-lib = {
    inherit
      parametric
      aspects
      __findFile
      statics
      owned
      isFn
      canTake
      take
      ;
  };
in
den-lib
