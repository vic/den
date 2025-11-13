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

  # creates an aspect that inherits class from fromAspect.
  owned =
    aspect:
    aspect
    // {
      includes = [ ];
      __functor =
        self:
        # deadnix: skip
        { class, aspect-chain }:
        self;
    };

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
    if isStatic f then
      f ctx
    else if !isFn f then
      f
    else
      { };

  isStatic = canTake {
    class = "";
    aspect-chain = [ ];
  };

  take.unused = _unused: used: used;
  take.exactly = take canTake.exactly;
  take.atLeast = take canTake.atLeast;
  take.__functor =
    _: takes: fn: ctx:
    if takes ctx fn then fn ctx else { };

  parametric.atLeast = funk (lib.flip take.atLeast);
  parametric.exactly = funk (lib.flip take.exactly);
  parametric.context = lib.flip parametric.atLeast;
  parametric.expands = attrs: funk (ctx: (lib.flip take.atLeast) (ctx // attrs));
  parametric.__functor =
    self: ctx:
    if ctx == true then
      self.atLeast
    else if ctx == false then
      self.exactly
    else if isFn ctx then
      funk ctx
    else
      self.context ctx;

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
