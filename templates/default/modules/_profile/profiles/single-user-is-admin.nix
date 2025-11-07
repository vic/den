{ den, lib, ... }:
{

  # When a host includes *ONLY* one user, make that user the admin.
  pro.single-user-is-admin =
    { fromUser, toHost }@context:
    let
      single = 1 == builtins.length (builtins.attrValues toHost.users);
      exists = single && builtins.hasAttr fromUser.name toHost.users;
      admin = lib.optionals exists [ den._.primary-user ];
      define = [ den._.define-user ];
    in
    {
      includes = map (f: f context) (define ++ admin);
    };
}
