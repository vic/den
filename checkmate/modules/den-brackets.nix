{ ... }@top:
let
  lib = top.inputs.nixpkgs.lib;

  # deadnix: skip
  __findFile =
    if true then
      import "${top.inputs.target}/nix/den-brackets.nix" { inherit lib config inputs; }
    else
      __findFile;

  inputs = {

  };

  config.den = {
    default.foo = 1;

    provides.foo.a = 2;
    provides.foo.provides.bar.b = 3;
    provides.foo.provides.c = 4;

    d = 5;

    aspects.foo.a = 6;
    aspects.foo.provides.bar.b = 7;
    aspects.foo.provides.c = 8;

  };
in
{
  flake.tests."<den.default>" =
    let
      expr = <den.default>;
      expected.foo = 2;
    in
    {
      inherit expr expected;
    };
}
