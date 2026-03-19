# Provides shell utilities under `den.sh` for building OS configurations using
# github:nix-community/nh instead of nixos-rebuild, etc
{ lib, den, ... }:
let
  defaultAction = "build";

  denShell =
    args: pkgs:
    pkgs.mkShell {
      buildInputs = [ pkgs.nh ] ++ (denApps args pkgs);
    };

  denPackages =
    args: pkgs:
    lib.listToAttrs (
      map (a: {
        name = a.name;
        value = a;
      }) (denApps args pkgs)
    );

  hosts = lib.concatMap lib.attrValues (lib.attrValues den.hosts);
  homes = lib.concatMap lib.attrValues (lib.attrValues den.homes);

  hostApps = args: pkgs: map (os args pkgs) hosts;
  homeApps = args: pkgs: map (hm args pkgs) homes;
  denApps = args: pkgs: (hostApps args pkgs) ++ (homeApps args pkgs);

  os =
    {
      outPrefix ? [ ],
      fromFlake ? true,
      fromPath ? ".",
    }:
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
          attr = lib.concatStringsSep "." (outPrefix ++ host.intoAttr);
          from =
            if fromFlake then
              [ "${fromPath}#${attr}" ]
            else
              [
                "--file"
                fromPath
                attr
              ];
          args = lib.concatStringsSep " " from;
        in
        ''
          action="''${1:-${defaultAction}}"
          shift || true
          exec nh ${command} "$action" ${args} "$@"
        '';
    };

  hm =
    {
      outPrefix ? [ ],
      fromFlake ? true,
      fromPath ? ".",
    }:
    pkgs: home:
    pkgs.writeShellApplication {
      name = home.name;
      runtimeInputs = [ pkgs.nh ];
      text =
        let
          attr = lib.concatStringsSep "." (outPrefix ++ home.intoAttr);
          from =
            if fromFlake then
              [ "${fromPath}#${attr}" ]
            else
              [
                "--file"
                fromPath
                attr
              ];
          args = lib.concatStringsSep " " from;
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
    denPackages
    denShell
    homeApps
    hostApps
    denApps
    ;
}
