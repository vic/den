# tests for extending `den.base.*` modules with capabilities (options).
# these allow you to expend all hosts/users/homes with custom option
# that can later be used by aspects for providing features.
#
{ lib, ... }:
{

  # This module is base for all host configs.
  den.base.host =
    { host, ... }:
    {
      options.capabilities.ssh-server = lib.mkEnableOption "Does host ${host.name} provide ssh?";
    };

  # This module is base for all user configs.
  den.base.user =
    { user, ... }:
    {
      options.isAdmin = lib.mkOption {
        type = lib.types.bool;
        default = user.name == "alice"; # only alice is always admin
      };
    };

  # This module is base for all home configs.
  # den.base.home = { home, ... }: { };

  # This one is included on each host/user/home
  # it cannot access host/user/home values since this conf is generic.
  den.base.conf = {
    options.foo = lib.mkOption {
      type = lib.types.str;
      default = "bar";
    };
  };

  # Now hosts and users can set any option defined in base modules.
  den.hosts.x86_64-linux.rockhopper = {
    capabilities.ssh-server = true;
    foo = "boo";
    users.alice = {
      # isAdmin = true;  # alice is admin by default, nothing explicit here.
      foo = "moo";
    };
  };

  den.aspects.rockhopper.includes =
    let
      # An aspect can make use of these options to provide configuration.
      sshCapable =
        { host, ... }:
        {
          nixos.services.sshd.enable = host.capabilities.ssh-server;
          homeManager.services.ssh-agent.enable = host.capabilities.ssh-server;
        };
    in
    [ sshCapable ];

  # CI checks
  perSystem =
    {
      checkCond,
      rockhopper,
      alice-at-rockhopper,
      ...
    }:
    {
      checks.host-conf-rockhopper-sshd = checkCond "sshd enabled" (
        rockhopper.config.services.sshd.enable == true
      );
      checks.host-conf-alice-sshd = checkCond "ssh-agent enabled" (
        alice-at-rockhopper.services.ssh-agent.enable == true
      );
    };

}
