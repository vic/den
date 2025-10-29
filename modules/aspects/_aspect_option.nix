{ inputs, lib }:
description:
lib.mkOption {
  inherit description;
  default = { };
  type = (inputs.flake-aspects.lib lib).types.aspectSubmodule;
}
