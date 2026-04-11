let
  description = ''
    A class generic aspect that enables insecure packages by name and version.

    Works for any class (nixos/darwin/homeManager,etc) on any host/user/home context.

    ## Usage

      den.aspects.my-laptop.includes = [ (den._.insecure [ "example-insecure-package-1.0.0" ]) ];

    It will dynamically provide a module for each class when accessed.
  '';

  __functor =
    _self: allowed-names:
    { class, ... }:
    if
      (builtins.elem class [
        "nixos"
        "darwin"
        "homeManager"
      ])
    then
      {
        ${class}.permittedInsecurePackages.packages = allowed-names;
      }
    else
      { };
in
{
  den.provides.insecure = {
    inherit description __functor;
  };
}
