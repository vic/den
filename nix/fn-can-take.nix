lib: param: f:
let
  args = lib.mapAttrsToList (name: optional: { inherit name optional; }) (lib.functionArgs f);
  empty = lib.length args == 0;

  givenAttrs = (builtins.isAttrs param) && !param ? __functor;

  required = map (x: x.name) (lib.filter (x: !x.optional) args);
  provided = lib.attrNames param;

  intersection = lib.intersectLists required provided;
  satisfied = lib.length required == lib.length intersection;

  noExtas = lib.length required == lib.length provided;
in
empty || (givenAttrs && satisfied && noExtas)
