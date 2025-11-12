{ inputs, den, ... }:
{
  imports = [ (inputs.den.namespace "eg" false) ];
  _module.args.__findFile = den.lib.__findFile;
}
