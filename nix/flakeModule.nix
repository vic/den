{ inputs, ... }:
{
  imports = [ (inputs.import-tree ../modules) ];
}
