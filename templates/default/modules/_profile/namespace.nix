# creates a `pro` aspect namespace.
#
# this is not required but helps you avoid writing
# `den.aspects.profile.provides` all the time
#  and use your namespace instead.
# This is inspired by vic's vix namespae.
#
# User TODO: rename `pro` to something else on your project.
# The namespace is accesible via the module args
# and also writable as an option at module root.
#
{ config, lib, ... }:
{
  # create a sub-tree of provided aspects.
  # the `profile` name is generic, use your own
  # as deep as you like, only that it ends in a provides tree.
  den.aspects.profile.provides = { };
  # setup for write
  imports = [ (lib.mkAliasOptionModule [ "pro" ] [ "den" "aspects" "profile" "provides" ]) ];
  # setup for read
  _module.args.pro = config.den.aspects.profile.provides;
  # optionally expose outside your flake.
  # flake.pro = config.den.aspects.profile.provides;
}
