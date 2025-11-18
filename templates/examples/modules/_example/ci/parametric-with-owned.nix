{ den, lib, ... }:
let
  # a test module to check context was forwarded
  fwdModule.nixos.options.fwd = {
    a = strOpt;
    b = strOpt;
    c = strOpt;
    d = strOpt;
    e = strOpt;
    f = strOpt;
    # unlike strings, pkgs cannot be duplicated, we use this to
    # ensure no-dups are created from parametric owned modules.
    pkg = lib.mkOption { type = lib.types.package; };
  };
  strOpt = lib.mkOption { type = lib.types.str; };

  inherit (den.lib) parametric;
in
{

  den.aspects.rockhopper.includes = [
    fwdModule
    den.aspects.fwd._.first
  ];
  den.aspects.rockhopper.nixos.fwd.c = "host owned C";

  # this aspect will take any context and also forward it
  # into any includes function that can take same context.
  den.aspects.fwd._.first = parametric {
    nixos =
      { pkgs, ... }:
      {
        fwd.a = "First owned A";
        fwd.pkg = pkgs.hello;
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
      nixos.fwd.b = "Second owned B for ${host.name}";
      includes = [ den.aspects.fwd._.third ];
    };

  den.aspects.fwd._.third =
    { third, ... }:
    {
      nixos.fwd.e = "Third ${third}";
    };

  den.aspects.fwd._.fourth = parametric.expands { planet = "Earth"; } {
    includes = [ den.aspects.fwd._.fifth ];
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
    { checkCond, rockhopper, ... }:
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
    };

}
