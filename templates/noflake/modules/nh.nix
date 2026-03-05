# Provides shell utilities under `den.sh` for building OS configurations using
# github:nix-community/nh instead of nixos-rebuild, etc
{ lib, den, ... }:
let
  defaultAction = "build";

  denShell =
    pkgs:
    pkgs.mkShell {
      buildInputs = [ pkgs.nh ] ++ (denApps pkgs);
    };

  hosts = lib.concatMap lib.attrValues (lib.attrValues den.hosts);
  homes = lib.concatMap lib.attrValues (lib.attrValues den.homes);

  denApps = pkgs: (map (os pkgs) hosts) ++ (map (hm pkgs) homes);

  os =
    pkgs: host:
    pkgs.writeShellApplication {
      name = host.name;
      runtimeInputs = [ pkgs.nh ];
      text =
        let
          command =
            {
              darwin = "darwin";
              nixos = "os";
            }
            .${host.class};
          attr = lib.concatStringsSep "." ([ "flake" ] ++ host.intoAttr);
          args = lib.concatStringsSep " " [
            "--file"
            "."
            attr
          ];
        in
        ''
          action="''${1:-${defaultAction}}"
          shift || true
          exec nh ${command} "$action" ${args} "$@"
        '';
    };

  hm =
    pkgs: home:
    pkgs.writeShellApplication {
      name = home.name;
      runtimeInputs = [ pkgs.nh ];
      text =
        let
          attr = lib.concatStringsSep "." ([ "flake" ] ++ home.intoAttr);
          args = lib.concatStringsSep " " [
            "--file"
            "."
            attr
          ];
        in
        ''
          action="''${1:-${defaultAction}}"
          shift || true
          exec nh home "$action" ${args} "$@"
        '';
    };
in
{
  options.den.sh = lib.mkOption {
    description = "Non-flake Den shell environment";
    default = denShell (import <nixpkgs> { });
  };
}
