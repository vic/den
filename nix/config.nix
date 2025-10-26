{
  config,
  lib,
  self,
  withSystem,
  ...
}:
let

  build = builder: cfg:
    let
      items = map builtins.attrValues (builtins.attrValues cfg);
      buildItem = item: {
        inherit (item) name intoAttr;
        value = builder item;
      };
    in map buildItem (lib.flatten items);

  osConfiguration =
    host:
    host.instantiate {
      inherit (host) system;
      modules = [ self.modules.${host.class}.${host.aspect} ];
    };

  homeConfiguration = home: 
    withSystem home.system (
      { pkgs, ... }:
      home.instantiate {
        inherit pkgs;
        modules = [ self.modules.${home.class}.${home.aspect} ];
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
