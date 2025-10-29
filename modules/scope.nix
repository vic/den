{ inputs, lib, ... }:
{
  imports = [ ((inputs.flake-aspects.lib lib).new-scope "den") ];
}
