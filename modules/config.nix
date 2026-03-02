{
  config,
  lib,
  ...
}:
let

  build =
    builder: cfg:
    let
      items = map builtins.attrValues (builtins.attrValues cfg);
      buildItem = item: lib.setAttrByPath item.intoAttr (builder item);
      built = map buildItem (lib.flatten items);
    in
    built;

  osConfiguration =
    host:
    host.instantiate {
      modules = [
        host.mainModule
        { nixpkgs.hostPlatform = lib.mkDefault host.system; }
      ];
    };

  homeConfiguration =
    home:
    home.instantiate {
      pkgs = home.pkgs;
      modules = [ home.mainModule ];
    };

  configs = (build osConfiguration config.den.hosts) ++ (build homeConfiguration config.den.homes);
in
{
  config.flake = lib.mkMerge configs;
}
