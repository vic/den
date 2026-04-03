{ lib, ... }:
let
  canTake =
    params: func:
    let
      valid = lib.isFunction func && builtins.isAttrs params;
      args = lib.functionArgs func;
      required = builtins.filter (n: !args.${n}) (builtins.attrNames args);
    in
    {
      satisfied = valid && builtins.all (n: params ? ${n}) required;
      exactly = valid && required == builtins.attrNames params;
    };
in
{
  __functor = self: self.atLeast;
  atLeast = params: func: (canTake params func).satisfied;
  upTo = params: func: (canTake params func).satisfied;
  exactly = params: func: (canTake params func).exactly;
}
