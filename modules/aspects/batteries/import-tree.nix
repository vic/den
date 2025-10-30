{
  inputs,
  lib,
  den,
  ...
}:
let
  import-tree.description = ''
    an aspect that recursively imports non-dendritic .nix files from a `_''${class}` directory.

      this can be used to help migrating from huge existing setups,
      by having files: path/_nixos/*.nix, path/_darwin/*.nix, etc.

    requirements:
      - inputs.import-tree

    usage:

      this aspect can be included explicitly on any aspect:

          # example: my-host will import _nixos or _darwin nix files automatically.
          den.aspects.my_host.includes = [ (den.import-tree { root = ./.; }) ];

      or it can be default imported per host/user/home:

          
          # each host will import-tree from ./hosts/''${host.name}/_{nixos,darwin}/*.nix
          den.default.host._.host.includes = [ (den.import-tree._.host { root = ./hosts; }) ];

          # each user will import-tree from ./users/''${user.name}@''${host.name}/_homeManager/*.nix
          den.default.user._.user.includes = [ (den.import-tree._.user { root = ./users; }) ];

          # each home will import-tree from ./homes/''${home.name}/_homeManager/*.nix
          den.default.home._.home.includes = [ (den.import-tree._.home { root = ./homes; }) ];

      you are also free to create your own auto-imports layout following the implementation of these.
  '';

  import-tree.__functor =
    _:
    { root }:
    { class, ... }:
    let
      path = "${toString root}/_${class}";
      aspect.${class}.imports = [
        (inputs.import-tree path)
      ];
    in
    if builtins.pathExists path then aspect else { };

  import-tree.provides = {
    host = { root }: { host }: import-tree { root = "${toString root}/${host.name}"; };
    user =
      { root }: { host, user }: import-tree { root = "${toString root}/${user.name}@${host.name}"; };
    home = { root }: { home }: import-tree { root = "${toString root}/${home.name}"; };
  };

  aspect-option = import ../_aspect_option.nix { inherit inputs lib; };

in
{
  config.den = { inherit import-tree; };
  options.den.import-tree = aspect-option "import-tree aspects";
}
