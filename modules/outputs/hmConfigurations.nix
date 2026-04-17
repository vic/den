{ lib, den, ... }:
let

  ctx.flake-system.into.flake-hm =
    { system }: map (home: { inherit home; }) (builtins.attrValues den.homes.${system} or { });

  ctx.flake-system.provides.flake-hm = _: hmFwd;

  hmFwd =
    { home }:
    den.provides.forward {
      each = lib.optional (home.intoAttr != [ ]) true;
      fromClass = _: home.class;
      intoClass = _: "flake";
      intoPath = _: [ "flake" ];
      fromAspect = _: den.ctx.home { inherit home; };
      mapModule =
        _: module:
        lib.setAttrByPath home.intoAttr (
          home.instantiate {
            pkgs = home.pkgs;
            modules = [ module ];
          }
        );
    };
in
{
  den.ctx = ctx;
}
