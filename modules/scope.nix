{
  inputs,
  config,
  lib,
  ...
}:
{
  config._module.args.den = config.den;
  imports = [ ((inputs.flake-aspects.lib lib).new-scope "den") ];
}
