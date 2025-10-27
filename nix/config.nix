{
  config,
  lib,
  withSystem,
  ...
}:
let

  build =
    builder: cfg:
    let
      items = map builtins.attrValues (builtins.attrValues cfg);
      buildItem = item: {
        inherit (item) name intoAttr;
        value = builder item;
      };
    in
    map buildItem (lib.flatten items);

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
    withSystem home.system (
      { pkgs, ... }:
      home.instantiate {
        inherit pkgs;
        modules = [ home.mainModule ];
      }
    );

  cfgs = (build osConfiguration config.den.hosts) ++ (build homeConfiguration config.den.homes);

  outputs =
    acc: item:
    acc
    // {
      ${item.intoAttr} = (acc.${item.intoAttr} or { }) // {
        ${item.name} = item.value;
      };
    };

in
{
  flake = lib.foldl outputs { } cfgs;
}
