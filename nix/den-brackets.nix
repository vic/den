# __findFile implementation to resolve deep aspects.
# inspired by https://fzakaria.com/2025/08/10/angle-brackets-in-a-nix-flake-world
#
# For user facing documentation, see:
# See templates/default/_profile/den-brackets.nix
# See templates/default/_profile/namespace.nix
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
      readFromDen = lib.getAttrFromPath tail config.den;

      headIsAspect = builtins.hasAttr head config.den.aspects;
      readFromAspects = lib.getAttrFromPath path config.den.aspects;

      headIsDenful = lib.hasAttrByPath [ "ful" head ] config.den;
      denfulTail = if lib.head tail == "provides" then lib.tail tail else tail;
      readFromDenful = lib.getAttrFromPath ([ head ] ++ denfulTail) config.den.ful;

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
  (findAspect)
]
