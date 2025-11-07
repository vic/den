lib: inputs:
let
  isFn = f: (builtins.isFunction f) || (f ? __functor);
  canTake = import ./fn-can-take.nix lib;
  inCtx = ctx: f: isFn f && canTake ctx f;

  isAspect = canTake {
    class = "";
    aspect-chain = [ ];
  };

  # creates an aspect that inherits class from fromAspect.
  owned = class: fromAspect: { ${class} = fromAspect.${class} or { }; };

  # only static includes from an aspect.
  statics =
    aspect:
    # deadnix: skip
    { class, aspect-chain }:
    {
      includes =
        let
          include =
            f:
            if !isFn f then
              f
            else if isAspect f then
              f { inherit class aspect-chain; }
            else
              { };
        in
        map include aspect.includes;
    };

  # "Just Give 'Em One of These" -  Moe Szyslak
  # a __functor that **only** considers parametric includes
  # that **exactly** match the given context.
  funk =
    aspect: ctx:
    let
      fns = builtins.filter (inCtx ctx) aspect.includes;
      includes = map (f: f ctx) fns;
    in
    {
      inherit includes;
    };

  parametric =
    param: aspect:
    if param == true then
      funk aspect
    else
      # deadnix: skip
      { class, aspect-chain }: funk aspect param;

  aspects = inputs.flake-aspects.lib lib;

  # EXPERIMENTAL.  __findFile to resolve deep aspects.
  #   __findFile = angleBrackets den.aspects;
  #   <foo/bar/baz> => den.aspects.foo.provides.bar.provides.baz
  # inspired by https://fzakaria.com/2025/08/10/angle-brackets-in-a-nix-flake-world
  angleBrackets =
    den-ns: _nixPath: name:
    lib.pipe name [
      (lib.replaceString "/" ".provides.")
      (lib.splitString ".")
      (path: lib.getAttrFromPath path den-ns)
    ];

  den-lib = {
    inherit
      parametric
      aspects
      angleBrackets
      statics
      owned
      isFn
      canTake
      ;
  };
in
den-lib
