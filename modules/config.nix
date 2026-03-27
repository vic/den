{
  config,
  lib,
  ...
}:
let

  build =
    builder: cfg:
    let
      items = lib.concatMap builtins.attrValues (builtins.attrValues cfg);
    in
    map (
      item: if item.intoAttr == [ ] then { } else lib.setAttrByPath item.intoAttr (builder item)
    ) items;

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
