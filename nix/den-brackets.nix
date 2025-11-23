# __findFile implementation to resolve deep aspects.
# inspired by https://fzakaria.com/2025/08/10/angle-brackets-in-a-nix-flake-world
{
  lib,
  config,
  ...
}:
_nixPath: name:
let

  findAspect =
    path:
    let
      head = lib.head path;
      tail = lib.tail path;

      notFound = "Aspect not found: ${lib.concatStringsSep "." path}";

      headIsDen = head == "den";
      readFromDen = lib.getAttrFromPath ([ "den" ] ++ tail) config;

      headIsAspect = builtins.hasAttr head config.den.aspects;
      aspectsPath = [
        "den"
        "aspects"
      ]
      ++ path;
      readFromAspects = lib.getAttrFromPath aspectsPath config;

      headIsDenful = lib.hasAttrByPath [ "ful" head ] config.den;
      denfulTail =
        if builtins.length tail > 0 && lib.head tail == "provides" then lib.tail tail else tail;
      denfulPath = [
        "den"
        "ful"
        head
      ]
      ++ denfulTail;
      readFromDenful = lib.getAttrFromPath denfulPath config;

      found =
        if headIsDen then
          readFromDen
        else if headIsAspect then
          readFromAspects
        else if headIsDenful then
          readFromDenful
        else
          throw notFound;
    in
    found;

in
lib.pipe name [
  (lib.strings.replaceStrings [ "/" ] [ ".provides." ])
  (lib.strings.splitString ".")
  findAspect
]
