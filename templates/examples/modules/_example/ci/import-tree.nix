# configures class-automatic module auto imports for hosts/users/homes.
# See documentation at modules/aspects/provides/import-tree.nix
{
  # deadnix: skip
  __findFile ? __findFile,
  ...
}:
{

  # alice imports non-dendritic <class> modules from _non_dendritic/alice/_<class>/*.nix
  den.aspects.alice.includes = [ (<den/import-tree> ./_non_dendritic/alice) ];

  # See the documentation at batteries/import-tree.nix
  den.default.includes = [
    (<den/import-tree/host> ./_non_dendritic/hosts)
    (<den/import-tree/user> ./_non_dendritic/users)
    (<den/import-tree/home> ./_non_dendritic/homes)
  ];

  # tests
  perSystem =
    { checkCond, rockhopper, ... }:
    {
      checks.import-tree = checkCond "auto-imported from rockhopper/_nixos" (
        rockhopper.config.auto-imported
      );
    };
}
