_lib: fnCanTake:
let
  isFn = f: (builtins.isFunction f) || (f ? __functor);
  apply =
    param: f:
    if !isFn f then
      f
    else if fnCanTake param f then
      f param
    else if
      fnCanTake {
        class = null;
        aspect-chain = [ ];
      } f
    then
      f
    else
      { };

  # static = aspect: {
  #   __functor =
  #     _:
  #     # deadnix: skip
  #     { class, aspect-chain }:
  #     {
  #       ${class} = aspect.${class} or { };
  #     };
  # };

  parametric = aspect: param: map (apply param) aspect.includes;

  __functor = aspect: param: {
    includes = (parametric aspect param);
  };
in
__functor
