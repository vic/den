{
  # Including an static aspect should not cause duplicate definitions
  den.aspects.alice.includes = [
    {
      homeManager =
        { pkgs, ... }:
        {
          programs.emacs.enable = true;
          programs.emacs.package = pkgs.emacs30-nox;
        };
    }
  ];

  perSystem =
    {
      checkCond,
      alice-at-rockhopper,
      lib,
      ...
    }:
    {
      checks.alice-custom-emacs = checkCond "set uniquely via a static includes" (
        let
          expr = lib.getName alice-at-rockhopper.programs.emacs.package;
          expected = "emacs-nox";
        in
        expr == expected
      );
    };
}
