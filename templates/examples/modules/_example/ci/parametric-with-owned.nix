{
  den,
  lib,
  ...
}:
let
  # a test module to check context was forwarded
  fwdModule.options.fwd = {
    a = strOpt;
    b = strOpt;
    c = strOpt;
    d = strOpt;
    e = strOpt;
    f = strOpt;
    # unlike strings, pkgs cannot be duplicated/merged, we use this to
    # ensure no-dups are created from parametric owned modules.
    pkg = pkgOpt;
    pkg2 = pkgOpt;
    pkg3 = pkgOpt;
  };
  strOpt = lib.mkOption { type = lib.types.str; };
  pkgOpt = lib.mkOption { type = lib.types.package; };

  inherit (den.lib) parametric;
in
{
  den.aspects.rockhopper.includes = [
    { nixos.imports = [ fwdModule ]; }
    { homeManager.imports = [ fwdModule ]; }
    den.aspects.fwd._.first
  ];
  den.aspects.rockhopper.nixos.fwd.c = "host owned C";
  den.aspects.rockhopper.homeManager.fwd.a = "host home-managed A";

  # this aspect will take any context and also forward it
  # into any includes function that can take same context.
  den.aspects.fwd._.first = parametric {
    nixos =
      { pkgs, ... }:
      {
        fwd.a = "First owned A";
        fwd.pkg = pkgs.hello;
      };
    homeManager =
      { pkgs, ... }:
      {
        fwd.pkg = pkgs.vim;
      };
    includes = [
      den.aspects.fwd._.second
      { nixos.fwd.d = "First static includes D"; }
      den.aspects.fwd._.never
      den.aspects.fwd._.fourth
    ];
  };

  # Note that second has named arguments, while first does not.
  # the first aspect forwards whatever context it receives.
  den.aspects.fwd._.second =
    { host, ... }:
    parametric.fixedTo { third = "Impact"; } {
      includes = [ den.aspects.fwd._.third ];
      nixos =
        { pkgs, ... }:
        {
          fwd.b = "Second owned B for ${host.name}";
          fwd.pkg2 = pkgs.bat;
        };
      homeManager =
        { pkgs, ... }:
        {
          fwd.pkg2 = pkgs.helix;
        };
    };

  den.aspects.fwd._.third =
    { third, ... }:
    {
      nixos.fwd.e = "Third ${third}";
    };

  den.aspects.fwd._.fourth = parametric.expands { planet = "Earth"; } {
    includes = [ den.aspects.fwd._.fifth ];
    nixos =
      { pkgs, ... }:
      {
        fwd.pkg3 = pkgs.emacs-nox;
      };
    homeManager =
      { pkgs, ... }:
      {
        fwd.pkg3 = pkgs.emacs-nox;
      };
  };

  den.aspects.fwd._.fifth =
    { host, planet, ... }:
    {
      nixos.fwd.f = "Fifth ${planet} ${host.name}";
    };

  den.aspects.fwd._.never =
    { never-matches }:
    {
      nixos.fwd.a = "Imposibru! should never be included ${never-matches}";
    };

  perSystem =
    {
      checkCond,
      rockhopper,
      alice-at-rockhopper,
      ...
    }:
    {
      checks.parametric-fwd-a = checkCond "fwd-a" (rockhopper.config.fwd.a == "First owned A");
      checks.parametric-fwd-b = checkCond "fwd-b" (
        rockhopper.config.fwd.b == "Second owned B for rockhopper"
      );
      checks.parametric-fwd-c = checkCond "fwd-c" (rockhopper.config.fwd.c == "host owned C");
      checks.parametric-fwd-d = checkCond "fwd-d" (rockhopper.config.fwd.d == "First static includes D");
      checks.parametric-fwd-e = checkCond "fwd-e" (rockhopper.config.fwd.e == "Third Impact");
      checks.parametric-fwd-f = checkCond "fwd-f" (rockhopper.config.fwd.f == "Fifth Earth rockhopper");

      checks.parametric-fwd-pkg = checkCond "fwd-pkg" (lib.getName rockhopper.config.fwd.pkg == "hello");
      checks.parametric-fwd-pkg2 = checkCond "fwd-pkg2" (lib.getName rockhopper.config.fwd.pkg2 == "bat");
      checks.parametric-fwd-pkg3 = checkCond "fwd-pkg3" (
        lib.getName rockhopper.config.fwd.pkg3 == "emacs-nox"
      );

      checks.parametric-fwd-hm-a = checkCond "fwd-hm-a" (
        alice-at-rockhopper.fwd.a == "host home-managed A"
      );
      checks.parametric-fwd-hm-pkg = checkCond "fwd-hm-pkg" (
        lib.getName alice-at-rockhopper.fwd.pkg == "vim"
      );
      checks.parametric-fwd-hm-pkg2 = checkCond "fwd-hm-pkg2" (
        lib.getName alice-at-rockhopper.fwd.pkg2 == "helix"
      );
      checks.parametric-fwd-hm-pkg3 = checkCond "fwd-hm-pkg3" (
        lib.getName alice-at-rockhopper.fwd.pkg3 == "emacs-nox"
      );
    };

}
