# configures class-automatic module auto imports for hosts/users/homes.
# See documentation at modules/aspects/provides/import-tree.nix
{ den, ... }:
let
  # EXPERIMENTAL FEATURE: __findFile enables angle brackets
  #   <import-tree/host> resolves to: den.provides.import-tree.provides.host
  # See lib.nix and https://fzakaria.com/2025/08/10/angle-brackets-in-a-nix-flake-world
  # deadnix: skip # this weird if is for my nixf-diagnose to skip unused __findFile.
  __findFile = if true then den.lib.angleBrackets den.provides else __findFile;
in
{

  # alice imports non-dendritic <class> modules from _non_dendritic/alice/_<class>/*.nix
  den.aspects.alice.includes = [ (<import-tree> ./_non_dendritic/alice) ];

  # See the documentation at batteries/import-tree.nix
  den.default.includes = [
    (<import-tree/host> ./_non_dendritic/hosts)
    (<import-tree/user> ./_non_dendritic/users)
    (<import-tree/home> ./_non_dendritic/homes)
  ];

}
