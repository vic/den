# USER TODO: remove this file.
# copy any desired module to your ./modules and let it be auto-imported.
{ inputs, ... }:
{
  imports = [
    # The _example directory contains CI tests for all den features.
    # use it as reference of usage, but not of best practices.
    (inputs.import-tree ./_example)

    # The _profile directory contains a minimal profile-based layout.
    (inputs.import-tree ./_profile)
  ];
}
