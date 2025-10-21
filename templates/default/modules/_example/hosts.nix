# This is a fully working example configuration.
# Feel free to remove it, adapt or split into several modules.
# See documentation at <den>/nix/types.nix
{
  den.hosts.rockhopper = {
    system = "x86_64-linux";
    users.alice = { };
  };
}
