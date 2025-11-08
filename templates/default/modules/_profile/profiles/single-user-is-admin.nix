{ den, lib, ... }:
{

  # When a host includes *ONLY* one user, make that user the admin.
  pro.single-user-is-admin =
    { userToHost, ... }@context:
    let
      inherit (userToHost) user host;
      single = 1 == builtins.length (builtins.attrValues host.users);
      exists = single && builtins.hasAttr user.name host.users;
      admin = lib.optionals exists [ den._.primary-user ];
    in
    {
      __functor = den.lib.parametric context;
      includes = [ den._.define-user ] ++ admin;
    };
}
