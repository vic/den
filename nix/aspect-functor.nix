lib:
let
  is-fn = f: (builtins.isFunction f) || (f ? __functor);
  can-take = import ./fn-can-take.nix lib;
  apply =
    param: f:
    if !is-fn f then
      f
    else if can-take param f then
      f param
    else if
      can-take {
        class = null;
        aspect-chain = [ ];
      } f
    then
      f
    else
      { };

  static = aspect: {
    __functor =
      _:
      # deadnix: skip
      { class, aspect-chain }:
      {
        ${class} = aspect.${class} or { };
      };
  };

  parametric = aspect: param: map (apply param) aspect.includes;

  __functor = aspect: param: {
    includes = [ (static aspect) ] ++ (parametric aspect param);
  };
in
__functor
