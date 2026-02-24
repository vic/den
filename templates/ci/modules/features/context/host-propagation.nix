{ denTest, ... }:
{

  # This test uses the `funny.names` test option to
  # demostrate different places and context-aspects that
  # can contribute configurations to the host.
  flake.tests.ctx-transformation.test-host = denTest (
    {
      den,
      lib,
      show,
      funnyNames,
      ...
    }:
    let
      inherit (den.lib) parametric take;

      keys = ctx: "{${builtins.concatStringsSep "," (builtins.attrNames ctx)}}";
    in
    {

      den.hosts.x86_64-linux.igloo.users.tux = { };

      den.aspects.igloo.funny.names = [ "host-owned" ];
      den.aspects.igloo.includes = [
        { funny.names = [ "host-static" ]; }

        (
          { host, ... }@ctx:
          {
            funny.names = [ "host-lax ${keys ctx}" ];
          }
        )
        (take.exactly (
          { host }:
          {
            funny.names = [ "host-exact" ];
          }
        ))
        (take.atLeast (
          { host, never }:
          {
            funny.names = [ "host-never" ];
          }
        ))

        (
          { host, user, ... }@ctx:
          {
            funny.names = [ "host+user-lax ${keys ctx}" ];
          }
        )
        (take.exactly (
          { host, user }:
          {
            funny.names = [ "host+user-exact" ];
          }
        ))
        (take.atLeast (
          {
            host,
            user,
            never,
          }:
          {
            funny.names = [ "host+user-never" ];
          }
        ))
      ];

      den.aspects.tux.funny.names = [ "user-owned" ];
      den.aspects.tux.includes = [
        { funny.names = [ "user-static" ]; }

        (
          { user, ... }@ctx:
          {
            funny.names = [ "user-lax ${keys ctx}" ];
          }
        )
        (take.exactly (
          { host, user }:
          {
            funny.names = [ "user-exact" ];
          }
        ))
        (take.atLeast (
          {
            host,
            user,
            never,
          }:
          {
            funny.names = [ "user-never" ];
          }
        ))
      ];

      den.ctx.hm-host.funny.names = [ "hm-host detected" ];
      den.ctx.hm-host.includes = [
        (
          { host, ... }@ctx:
          {
            funny.names = [ "hm-host host-lax ${keys ctx}" ];
          }
        )
      ];

      den.ctx.hm-user.includes = [
        (
          { host, user, ... }@ctx:
          {
            funny.names = [ "hm-user lax ${keys ctx}" ];
          }
        )
      ];

      den.default.funny.names = [ "default-owned" ];
      den.default.includes = [
        { funny.names = [ "default-static" ]; }
        (ctx: { funny.names = [ "default-anyctx ${keys ctx}" ]; })

        (
          { host, ... }@ctx:
          {
            funny.names = [ "default-host-lax ${keys ctx}" ];
          }
        )
        (
          { user, ... }@ctx:
          {
            funny.names = [ "default-user-lax ${keys ctx}" ];
          }
        )
        (
          { host, user, ... }@ctx:
          {
            funny.names = [ "default-host+user-lax ${keys ctx}" ];
          }
        )

        # the following error means an aspect is not parametric but static. (document this)
        # > error: function 'anonymous lambda' called without required argument 'user'
      ];

      expr = funnyNames (
        den.ctx.host {
          host = den.hosts.x86_64-linux.igloo;
        }
      );

      expected = [
        "default-anyctx {aspect-chain,class}"
        "default-anyctx {host,user}"
        "default-anyctx {host}"

        "default-host+user-lax {host,user}"
        "default-host-lax {host,user}"
        "default-host-lax {host}"

        "default-owned"

        "default-static"

        "default-user-lax {host,user}"

        "hm-host detected"
        "hm-host host-lax {host}"
        "hm-user lax {host,user}"

        "host+user-exact"
        "host+user-lax {host,user}"

        "host-exact"
        "host-lax {host,user}"
        "host-lax {host}"

        "host-owned"
        "host-static"

        "user-exact"
        "user-lax {host,user}"
        "user-owned"
        "user-static"
      ];

    }
  );

}
