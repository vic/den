{ inputs, lib, ... }:
{
  flake-file.inputs.den.url = lib.mkDefault "github:vic/den";

  imports = [
    inputs.den.flakeModule

    # USER TODO: remove this import-tree
    # copy any desired module to your ./modules and let it be auto-imported.
    (inputs.import-tree ./_example)
  ];
}
