{ inputs, ... }:
{
  imports = [ (inputs.target.nixModule inputs) ];
}
