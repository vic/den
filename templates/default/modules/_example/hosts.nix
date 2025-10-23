# This is a fully working example configuration.
# Feel free to remove it, adapt or split into several modules.
# See documentation at <den>/nix/types.nix
{
  den.hosts = {
    rockhopper = {
      description = "rockhopper is a kind of penguin";
      system = "x86_64-linux";
      users.alice = { };
    };
    honeycrisp = {
      description = "nix-darwin on MacOS";
      system = "aarch64-darwin";
      users.alice = { };
    };
    emperor = {
      description = "nixos on MacMini";
      system = "aarch64-linux";
      users.alice = { };
    };
    adelie = {
      description = "wsl on windows";
      system = "x86_64-linux";
      users.alice = { };
    };
  };
}
