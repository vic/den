{
  den._.unfree.description = ''
    A class generic aspect that enables unfree packages by name.

    Works for any class (nixos/darwin/homeManager,etc).

    ## Usage

      den.aspects.my-laptop.includes = [ (den._.unfree { allow = [ "code" ]; }) ];

    It will dynamically provide a module for each class when accessed.
  '';

  den._.unfree.__functor =
    _:
    { allow }:
    { class, ... }:
    {
      ${class} =
        { lib, ... }:
        {
          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allow;
        };
    };
}
