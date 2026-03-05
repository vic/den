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

  hostApps = pkgs: map (os pkgs) hosts;
  homeApps = pkgs: map (hm pkgs) homes;
  denApps = pkgs: (hostApps pkgs) ++ (homeApps pkgs);

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
  inherit
    denShell
    homeApps
    hostApps
    denApps
    ;
}
