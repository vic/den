{ den, lib, ... }:
let
  # a test module to check context was forwarded
  fwdModule.nixos.options.fwd = {
    a = strOpt;
    b = strOpt;
    c = strOpt;
    d = strOpt;
  };
  strOpt = lib.mkOption { type = lib.types.str; };
in
{

  den.aspects.rockhopper.includes = [
    fwdModule
    den.aspects.fwd._.first
  ];
  den.aspects.rockhopper.nixos.fwd.c = "host owned C";

  # this is an `atLeast` parametric aspect that also includes
  # its owned configs and static (non-functional) includes.
  # Usage: just call `parametric` with an aspect.
  # or alternatively, set `__functor = den.lib.parametric;`
  den.aspects.fwd._.first = den.lib.parametric {
    nixos.fwd.a = "First owned A";
    includes = [
      den.aspects.fwd._.second
      { nixos.fwd.d = "First static includes D"; }
      den.aspects.fwd._.never
    ];
  };

  # Note that second has named arguments, while first does not.
  # the first aspect forwards whatever context it receives.
  den.aspects.fwd._.second =
    { host, ... }:
    {
      nixos.fwd.b = "Second owned B for ${host.name}";
    };

  den.aspects.fwd._.never =
    { never-matches }:
    {
      nixos.fwd.a = "Imposibru! should never be included ${never-matches}";
    };

  perSystem =
    { checkCond, rockhopper, ... }:
    {
      checks.parametric-fwd = checkCond "forwarding ctx with owned" (
        rockhopper.config.fwd.a == "First owned A"
        && rockhopper.config.fwd.b == "Second owned B for rockhopper"
        && rockhopper.config.fwd.c == "host owned C"
        && rockhopper.config.fwd.d == "First static includes D"
      );
    };

}
