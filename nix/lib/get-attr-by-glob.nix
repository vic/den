{ lib, ... }:
path: attrs:
let
  inherit (lib) getAttrFromPath;

in
getAttrFromPath path attrs
