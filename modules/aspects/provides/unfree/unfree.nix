{ den, ... }:
{
  den.provides.unfree.description = ''
    A class generic aspect that enables unfree packages by name.

    Works for any class (nixos/darwin/homeManager,etc) on any host/user/home context.

    ## Usage

      den.aspects.my-laptop.includes = [ (den._.unfree [ "code" ]) ];

    It will dynamically provide a module for each class when accessed.
  '';

  den.provides.unfree.__functor =
    _self: allowed-names:
    { class, aspect-chain }:
    den.lib.take.unused aspect-chain {
      ${class}.unfree.packages = allowed-names;
    };
}
