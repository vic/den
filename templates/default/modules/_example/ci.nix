# Adds some checks for CI
{ self, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      checkFile =
        name: file:
        pkgs.runCommandLocal name { } ''
          ls -la ${file} | tee $out
        '';

      checkCond =
        name: cond:
        let
          code = if cond then "touch $out" else ''echo "Cond-Failed: ${name}"'';
        in
        pkgs.runCommandLocal name { } code;

      rockhopper = self.nixosConfigurations.rockhopper;
      honeycrisp = self.darwinConfigurations.honeycrisp;
      adelie = self.wslConfigurations.adelie;
      cam = self.homeConfigurations.cam;
      bob = self.homeConfigurations.bob;
      luke = self.homeConfigurations.luke;

      alice-at-rockhopper = rockhopper.config.home-manager.users.alice;
      alice-at-honeycrisp = honeycrisp.config.home-manager.users.alice;

      checks.x86_64-linux = {
        vm = checkFile "vm-builds" "${rockhopper.config.system.build.vm}/bin/run-rockhopper-vm";

        hosts-rockhopper = checkFile "nixos-builds" rockhopper.config.system.build.toplevel;
        homes-cam = checkFile "home-builds" cam.activation-script;

        rockhopper-hostname = checkCond "den.default.host.includes sets hostName" (
          rockhopper.config.networking.hostName == "rockhopper"
        );
        honeycrisp-hostname = checkCond "den.default.host.includes sets hostName" (
          honeycrisp.config.networking.hostName == "honeycrisp"
        );
        alice-primary-on-macos = checkCond "den._.primary-user sets macos primary" (
          honeycrisp.config.system.primaryUser == "alice"
        );
        alice-exists-on-rockhopper = checkCond "den.default.user.includes defines user on host" (
          rockhopper.config.users.users.alice.isNormalUser
        );
        alice-not-exists-on-adelie = checkCond "den.default.user.includes defines user on host" (
          !adelie.config.users.users ? alice
        );
        will-exists-on-adelie = checkCond "den.default.user.includes defines user on host" (
          adelie.config.users.users.will.isNormalUser
        );
        will-is-wsl-default = checkCond "wsl.defaultUser defined" (adelie.config.wsl.defaultUser == "will");

        import-tree = checkCond "auto-imported from rockhopper/_nixos" (rockhopper.config.auto-imported);

        user-contributes-to-host = checkCond "alice.nixos sets on rockhopper host" (
          rockhopper.config.users.users.alice.description == "Alice Q. User"
        );

        host-contributes-to-user = checkCond "rockhopper contributes to all its users" (
          alice-at-rockhopper.programs.direnv.enable
        );

        alice-hm-fish-enabled-by-default = checkCond "home-managed fish for alice" (
          alice-at-rockhopper.programs.fish.enable
        );
        alice-hm-helix-enabled-by-user = checkCond "home-managed helix for alice" (
          alice-at-rockhopper.programs.helix.enable
        );

        alice-hm-git-enabled-on = checkCond "home-managed git for alice at rockhopper" (
          alice-at-rockhopper.programs.git.enable
        );
        alice-hm-git-enabled-off = checkCond "home-managed git for alice at honeycrisp" (
          !alice-at-honeycrisp.programs.git.enable
        );

        alice-os-tmux-enabled-on = checkCond "os tmux for hosts having alice" (
          rockhopper.config.programs.tmux.enable
        );
        alice-os-tmux-enabled-off = checkCond "os tmux for hosts having alice" (
          !honeycrisp.config.programs.tmux.enable
        );

        will-always-love-you = checkCond "red-snapper fish is default shell" (
          "fish" == lib.getName adelie.config.users.users.will.shell
        );

        luke-hm-depends-on-osConfig = checkCond "standalone hm can depend on osConfig" (
          luke.config.programs.bat.enable
        );

        alice-hello-enabled-by-default = checkCond "added hello at user packages" (
          let
            progs = rockhopper.config.users.users.alice.packages;
            expr = map lib.getName progs;
            expected = [ "hello" ];
          in
          expr == expected
        );

        rockhopper-names-single-entry = checkCond "custom nixos array option set once" (
          rockhopper.config.names == [ "tux" ]
        );

      };

      checks.aarch64-darwin = {
        hosts-honeyscrisp = checkFile "darwin-builds" honeycrisp.config.system.build.toplevel;
        homes-bob = checkFile "darwin-home-builds" bob.activation-script;
      };
    in
    {
      checks = checks.${pkgs.system} or { };
    };
}
