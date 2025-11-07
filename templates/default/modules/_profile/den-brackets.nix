# This enables den's angle brackets opt-in feature.
# Remove this file to opt-out.
#
# When den.lib.__findFile is in scope, you can do:
#
#   <pro/foo/bar> and it will resolve to:
#   den.aspects.pro.provides.foo.provides.bar
#
#   <pro/foo.includes> resolves to:
#   den.aspects.pro.provides.foo.includes
#
#   <den/import-tree/home> resolves to:
#   den.provides.import-tree.provides.home
#
#   <den.default> resolves to den.default
#
#   When the vix remote namespace is enabled
#   <vix/foo> resolves to: den.ful.vix.provides.foo
#
# Usage:
#
# Bring `__findFile` into scope from module args:
#
#   { __findFile, ... }:
#     den.default.includes = [ <den/home-manager> ];
#   }
#
# IF you are using nixf-diagnose, it will complain
# about __findFile not being used, trick it with:
#
#   { __findFile ? __findFile, ... }
#
{ den, ... }:
{
  _module.args.__findFile = den.lib.__findFile;
}
