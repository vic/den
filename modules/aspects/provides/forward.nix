{ lib, ... }:
let

  description = ''
    WIP: Creates a class-forwarding aspect.
  '';

  forward =
    cb:
    { class, aspect-chain }:
    let
      fwd = cb { inherit class aspect-chain; };
      include =
        item:
        let
          from = fwd.from item;
          into = fwd.into item;
          aspect = fwd.aspect item;
          module = aspect.resolve { class = from; };
        in
        lib.setAttrByPath into { imports = [ module ]; };
    in
    {
      includes = map include fwd.each;
    };

in
{
  den.provides.forward = {
    inherit description;
    __functor = _self: forward;
  };
}
