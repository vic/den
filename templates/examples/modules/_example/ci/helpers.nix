{ self, ... }:
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
    in
    {
      _module.args = {
        inherit checkCond checkFile;
        inherit rockhopper honeycrisp adelie;
        inherit cam bob luke;
        inherit alice-at-rockhopper alice-at-honeycrisp;
      };
    };
}
