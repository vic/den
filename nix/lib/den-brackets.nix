{
  lib,
  config,
  den,
  ...
}:
_nixPath: name:
let
  findAspect =
    path:
    let
      head = lib.head path;
      tail = lib.tail path;
    in
    if head == "den" then
      den.lib.getAttrByGlob ([ "den" ] ++ tail) config
    else if builtins.hasAttr head config.den.aspects then
      den.lib.getAttrByGlob (
        [
          "den"
          "aspects"
        ]
        ++ path
      ) config
    else if lib.hasAttrByPath [ "ful" head ] config.den then
      let
        denfulTail = if tail != [ ] && lib.head tail == "provides" then lib.tail tail else tail;
      in
      den.lib.getAttrByGlob (
        [
          "den"
          "ful"
          head
        ]
        ++ denfulTail
      ) config
    else
      throw "Aspect not found: ${lib.concatStringsSep "." path}";
in
lib.pipe name [
  (lib.strings.replaceStrings [ "/" ] [ ".provides." ])
  (lib.strings.splitString ".")
  findAspect
]
