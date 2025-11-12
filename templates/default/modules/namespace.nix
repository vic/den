{ inputs, den, ... }:
{
  # create an `eg` (example!) namespace.
  imports = [ (inputs.den.namespace "eg" false) ];

  # you can have more than one namespace, create yours.
  # imports = [ (inputs.den.namespace "yours" true) ];

  # you can also import namespaces from remote flakes.
  # imports = [ (inputs.den.namespace "ours" inputs.theirs) ];

  # this line enables den angle brackets syntax in modules.
  _module.args.__findFile = den.lib.__findFile;
}
