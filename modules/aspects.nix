{ den, lib, ... }:
{
  options.den.ful = lib.mkOption {
    defaultText = lib.literalExpression "{ }";
    default = { };
    description = "Den namespaces. Internal aspect trees.";
    internal = true;
    visible = false;
    type = lib.types.attrsOf den.lib.nsTypes.namespaceType;
  };
  options.flake.denful = lib.mkOption {
    defaultText = lib.literalExpression "{ }";
    default = { };
    type = lib.types.attrsOf lib.types.raw;
    description = "Flake exposed denful namespaces. Import using den.namespace.";
    internal = true;
    visible = false;
  };
}
