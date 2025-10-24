# USER TODO: remove this file.
# copy any desired module to your ./modules and let it be auto-imported.
{ inputs, ... }:
{
  imports = [ (inputs.import-tree ./_example) ];
}
