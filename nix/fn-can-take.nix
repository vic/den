lib:
let
  check =
    params: func:
    let
      givenArgs = builtins.isAttrs params;
      fargs = lib.functionArgs func;
      provided = builtins.attrNames params;
      args = lib.mapAttrsToList (name: optional: { inherit name optional; }) fargs;
      required = map (x: x.name) (lib.filter (x: !x.optional) args);
      intersection = lib.intersectLists required provided;
      satisfied = givenArgs && lib.length required == lib.length intersection;
      noExtras = lib.length required == lib.length provided;
      exactly = satisfied && noExtras;
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
