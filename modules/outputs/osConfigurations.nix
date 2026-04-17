{ lib, den, ... }:
let
  ctx.flake-system.into.flake-os =
    { system }: map (host: { inherit host; }) (builtins.attrValues den.hosts.${system} or { });

  ctx.flake-system.provides.flake-os = _: osFwd;

  osFwd =
    { host }:
    den.provides.forward {
      each = lib.optional (host.intoAttr != [ ]) true;
      fromClass = _: host.class;
      intoClass = _: "flake";
      intoPath = _: [ "flake" ];
      fromAspect = _: den.ctx.host { inherit host; };
      mapModule =
        _: module:
        lib.setAttrByPath host.intoAttr (
          host.instantiate {
            modules = [
              module
              { nixpkgs.hostPlatform = lib.mkDefault host.system; }
            ];
          }
        );
    };
in
{
  den.ctx = ctx;
}
