{ inputs, den, ... }:
{
  # create an `eg` (example!) namespace.
  imports = [ (inputs.den.namespace "eg" true) ];
}
