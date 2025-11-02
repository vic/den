{ den, lib, ... }:
{

  # When a host includes *ONLY* one user, make that user the admin.
  pro.single-user-is-admin =
    { host, user }@ctx:
    let
      one-user = 1 == builtins.length (builtins.attrValues host.users);
      is-admin = one-user && builtins.hasAttr user.name host.users;
      admin = lib.optionals is-admin [ (den._.primary-user ctx) ];
      define = [ (den._.define-user ctx) ];
    in
    {
      includes = define ++ admin;
    };
}
