# This is a fully working example configuration.
# Feel free to remove it, adapt or split into several modules.
# See documentation at <den>/nix/types.nix
{
  den.hosts.aarch64-darwin.honeycrisp.users.alice = { };
  den.hosts.aarch64-linux.emperor.users.alice = { };
  den.hosts.x86_64-linux = {
    rockhopper = {
      description = "rockhopper is a kind of penguin";
      users.alice = { };
    };
    adelie = {
      description = "wsl on windows";
      users.alice = { };
    };
  };
}
