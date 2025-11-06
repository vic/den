lib: inputs:
let
  fnCanTake = import ./fn-can-take.nix lib;

  # "Just Give 'Em One of These" -  Moe Szyslak
  funk = import ./aspect-functor.nix lib fnCanTake;

  parametric =
    param: aspect:
    if param == true then
      funk aspect
    else
      # deadnix: skip
      { class, aspect-chain }: funk aspect param;

  dependencies = import ./dependencies.nix { inherit parametric; };

  aspects = inputs.flake-aspects.lib lib;

  # EXPERIMENTAL.  __findFile to resolve deep aspects.
  #   __findFile = angleBrackets den.aspects;
  #   <foo/bar/baz> => den.aspects.foo.provides.bar.provides.baz
  # inspired by https://fzakaria.com/2025/08/10/angle-brackets-in-a-nix-flake-world
  angleBrackets =
    den-ns: _nixPath: name:
    lib.pipe name [
      (lib.replaceString "/" ".provides.")
      (lib.splitString ".")
      (path: lib.getAttrFromPath path den-ns)
    ];

in
{
  inherit
    fnCanTake
    funk
    parametric
    aspects
    angleBrackets
    dependencies
    ;
}
