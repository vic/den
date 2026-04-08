{ lib, ... }:
path: attrs:
let
  inherit (lib) getAttrFromPath;

  # The list of special characters for expanding glob patterns
  operators = [
    "{"
    "}"
    "*"
    ","
  ];

in
getAttrFromPath path attrs
