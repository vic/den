lib:
let
  check =
    params: func:
    let
      givenFn = builtins.isFunction func || (builtins.isAttrs func && func ? __functor);
      fargs = lib.functionArgs func;
      required = lib.filterAttrs (_: optional: !optional) fargs;
      reqNames = builtins.attrNames required;
      satisfied = givenFn && builtins.isAttrs params && builtins.all (n: params ? ${n}) reqNames;
      exactly = satisfied && builtins.length reqNames == builtins.length (builtins.attrNames params);
    in
    {
      inherit satisfied exactly;
    };
in
{
  __functor = self: self.atLeast;
  atLeast = params: func: (check params func).satisfied;
  exactly = params: func: (check params func).exactly;
}
