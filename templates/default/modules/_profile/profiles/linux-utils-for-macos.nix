{

  # example custom profile per platform system, see profiles.nix
  pro.aarch64-darwin.darwin =
    { pkgs, ... }:
    {
      # provide a consistent environment with linux.
      environment.systemPackages = [
        pkgs.coreutils
        pkgs.util-linux
      ];
    };

}
