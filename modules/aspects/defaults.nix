{
  den =
    { lib, ... }:
    {
      imports = [ (lib.mkAliasOptionModule [ "default" ] [ "ctx" "default" ]) ];

      ctx.default._.default = _: { };

    };
}
