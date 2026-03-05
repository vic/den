{
  den-lib,
  config,
  lib,
  inputs,
  ...
}@args:
{
  _module.args.den = config.den;
  imports = map (f: import f args) [
    ./lib.nix
    ./ctx.nix
    ./aspects.nix
  ];
}
