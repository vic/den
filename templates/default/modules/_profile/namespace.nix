# This module creates an aspect namespace.
#
# Just add the following import:
#
#     # define local namespace. enable flake output.
#     imports = [ (inputs.den.namespace "vix" true) ];
#
#     # you can use remote namespaces and they will merge
#     imports = [ (inputs.den.namespace "vix" inputs.dendrix) ];
#
# Internally, a namespace is just a `provides` branch:
#
#     # den.ful is the social-convention for namespaces.
#     den.ful.<name>
#
# Having an aspect namespace is not required but helps a lot
# with organization and conventient access to your aspects.
#
# The following examples use the `vix` namespace,
# inspired by github:vic/vix own namespace pattern.
#
# By using an aspect namespace you can:
#
# - Directly write to aspects in your namespace.
#
#    {
#       vix.gaming.nixos = ...;
#
#       # instead of:
#       # den.ful.vix.gaming.nixos = ...;
#    }
#
# - Directly read aspects from your namespace.
#
#    # Access the namespace from module args
#    { vix, ... }:
#    {
#       den.default.includes = [ vix.security ];
#
#       # instead of:
#       # den.default.includes = [ den.ful.vix.security ];
#    }
#
# - Share and re-use aspects between Dendritic flakes
#
#    # Aspects opt-in exposed as flake.denful.<name>
#    { imports = [( inputs.den.namespace "vix" true)] }
#
#    # Many flakes can expose to the same namespace and we
#    # can merge them, accessing aspects in a uniform way.
#    { imports = [( inputs.den.namespace "vix" inputs.dendrix )] }
#
# - Use angle-brackets to access deeply nested trees
#
#    # Be sure to read _profile/den-brackets.nix
#    { __findFile, ... }:
#       den.aspects.my-laptop.includes = [ <vix/gaming/retro> ];
#    }
#
#
# You can of course choose to not have any of the above.
# USER TODO: Remove this file for not using a namespace.
# USER TODO: Replace `pro` and update other files using it.
{ inputs, ... }:
{
  imports = [ (inputs.den.namespace "pro" true) ];
}
