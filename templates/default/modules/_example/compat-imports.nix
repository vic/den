# configures class-automatic module auto imports for hosts/users/homes.
# See _example/hosts/*/_${class}/*.nix
{ den, ... }:
{

  # alice imports non-dendritic <class> modules from _compat/alice/_<class>/*.nix
  den.aspects.alice.includes = [ (den._.import-tree { root = ./_compat/alice; }) ];

  # See the documentation at batteries/import-tree.nix
  den.default.host._.host.includes = [ (den._.import-tree._.host { root = ./_compat/hosts; }) ];
  den.default.user._.user.includes = [ (den._.import-tree._.user { root = ./_compat/users; }) ];
  den.default.home._.home.includes = [ (den._.import-tree._.home { root = ./_compat/homes; }) ];

}
