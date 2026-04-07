{ lib, ... }:
let
  canTake =
    params: func:
    let
      valid = lib.isFunction func && builtins.isAttrs params;
      args = lib.functionArgs func;
      required = builtins.filter (n: !args.${n}) (builtins.attrNames args);
      intersect = builtins.intersectAttrs args params;
      satisfied = valid && builtins.all (n: params ? ${n}) required;
    in
    {
      satisfied = satisfied;
      exactly = valid && required == builtins.attrNames params;
      upTo = satisfied && intersect != { };
    };
in
{
  __functor = self: self.atLeast;
  atLeast = params: func: (canTake params func).satisfied;
  exactly = params: func: (canTake params func).exactly;
  upTo = params: func: (canTake params func).upTo;
}
