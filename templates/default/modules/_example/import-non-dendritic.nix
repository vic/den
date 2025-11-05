# configures class-automatic module auto imports for hosts/users/homes.
# See documentation at modules/aspects/provides/import-tree.nix
{ den, ... }:
{

  # alice imports non-dendritic <class> modules from _non_dendritic/alice/_<class>/*.nix
  den.aspects.alice.includes = [ (den._.import-tree ./_non_dendritic/alice) ];

  # See the documentation at batteries/import-tree.nix
  den.default.includes = [
    (den._.import-tree._.host ./_non_dendritic/hosts)
    (den._.import-tree._.user ./_non_dendritic/users)
    (den._.import-tree._.home ./_non_dendritic/homes)
  ];

}
