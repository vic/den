{ inputs, den, ... }:
{
  # create an `eg` (example!) namespace. (flake exposed)
  imports = [ (inputs.den.namespace "eg" true) ];

  # you can have more than one namespace (false = not flake exposed)
  # imports = [ (inputs.den.namespace "my" false) ];

  # you can also merge many namespaces from remote flakes.
  # keep in mind a namespace is defined only once, so give it an array:
  # imports = [ (inputs.den.namespace "ours" [inputs.ours inputs.theirs]) ];

  # this line enables den angle brackets syntax in modules.
  _module.args.__findFile = den.lib.__findFile;
}
