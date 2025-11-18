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

  isFn = f: (builtins.isFunction f) || (f ? __functor);
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
        # deadnix: skip
        { class, aspect-chain }@ctx:
        funk applyStatics self ctx;
    };

  applyStatics =
    ctx: f:
    if !isFn f then
      f
    else if isStatic f && ctx ? class then
      f ctx
    else
      { };

  isStatic = canTake.atLeast {
    class = "";
    aspect-chain = [ ];
  };
  isCtxStatic = (lib.flip canTake.exactly) (
    # deadnix: skip
    { class, aspect-chain }: true
  );

  take.unused = _unused: used: used;
  take.exactly = take canTake.exactly;
  take.atLeast = take canTake.atLeast;
  take.__functor =
    _: takes: fn: ctx:
    if takes ctx fn then fn ctx else { };

  parametric.atLeast = funk (lib.flip take.atLeast);
  parametric.exactly = funk (lib.flip take.exactly);
  parametric.expands =
    attrs: aspect: ctx:
    parametric.fixedTo (ctx // attrs) aspect;
  parametric.fixedTo =
    ctx: aspect:
    { class, aspect-chain }:
    {
      includes = [
        (parametric.atLeast aspect ctx)
        (parametricStatics aspect { inherit class aspect-chain; })
      ];
    };
  parametric.withOwn =
    functor: aspect:
    aspect
    // {
      __functor = self: ctx: {
        includes = [
          (functor self ctx)
          (parametricStatics self ctx)
        ];
      };
    };
  parametric.__functor = _: parametric.withOwn parametric.atLeast;

  parametricStatics = self: ctx: {
    includes = lib.optionals (isCtxStatic ctx) [
      (owned self)
      {
        includes = map (applyStatics ctx) self.includes;
      }
    ];
  };

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
