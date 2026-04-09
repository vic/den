{ lib, den, ... }:
{
  _module.args.__findFile = den.lib.__findFile;

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.hosts.x86_64-linux = {
    laptop.users.alice = { };
    desktop-gdm.users.alice = { };
    web-server.users.deploy = { };
    mail-relay.users.deploy = { };
    devbox.users.alice = { };
    provider-filter.users.deploy = { };
    angle-brackets.users.alice = { };
    multi-desktop.users = {
      alice = { };
      bob = { };
    };
  };
}
