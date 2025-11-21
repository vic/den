{
  inputs,
  den,
  ...
}:
{
  den.provides.import-tree.description = ''
    Recursively imports non-dendritic .nix files depending on their Nix configuration `class`.

    This can be used to help migrating from huge existing setups.


    ```
      # this is at <repo>/modules/non-dendritic.nix
      den.aspects.my-laptop.includes = [
        (den._.import-tree._.host ../non-dendritic)
      ]
    ```

    With following structure, it will automatically load modules depending on their class.

    ```
       <repo>/
         modules/
           non-dendritic.nix # configures this aspect
         non-dendritic/ # name is just an example here
           hosts/
             my-laptop/
               _nixos/          # a directory for `nixos` class
                 auto-generated-hardware.nix # any nixos module
               _darwin/ 
                 foo.nix
               _homeManager/
                 me.nix
    ```

    ## Requirements

      - inputs.import-tree

    ## Usage

      this aspect can be included explicitly on any aspect:

          # example: will import ./disko/_nixos files automatically.
          den.aspects.my-disko.includes = [ (den._.import-tree ./disko/) ];

      or it can be default imported per host/user/home:

          # load from ./hosts/<host>/_nixos
          den.default.includes = [ (den._.import-tree._.host ./hosts) ];

          # load from ./users/<user>/{_homeManager, _nixos}
          den.default.includes = [ (den._.import-tree._.user ./users) ];

          # load from ./homes/<home>/_homeManager
          den.default.includes = [ (den._.import-tree._.home ./homes) ];

      you are also free to create your own auto-imports layout following the implementation of these.
  '';

  den._.import-tree.__functor =
    _: root:
    { class, aspect-chain }:
    let
      path = den.lib.take.unused aspect-chain "${toString root}/_${class}";
      aspect.${class}.imports = [ (inputs.import-tree path) ];
    in
    if builtins.pathExists path then aspect else { };

  den._.import-tree.provides = {
    host = root: { host, ... }: den._.import-tree "${toString root}/${host.name}";
    home = root: { home, ... }: den._.import-tree "${toString root}/${home.name}";
    user = root: { user, ... }: den._.import-tree "${toString root}/${user.name}";
  };
}
