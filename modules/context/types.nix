# den.ctx — Declarative context definitions.
#
# A context is an attribute set whose attrNames (not values) determine
# which parametric functions match. den.ctx provides named context
# types with declarative transformations and aspect lookup.
#
# Named contexts carry semantic meaning beyond their structure.
# ctx.host { host } and ctx.hm-host { host } hold the same data,
# but hm-host guarantees home-manager support was validated —
# following transform-don't-validate: you cannot obtain an hm-host
# unless all detection criteria passed.
#
# Context types are independent of NixOS. Den can be used as a library
# for any domain configurable through Nix (cloud infra, containers,
# helm charts, etc). The OS framework is one implementation on top of
# this context+aspects library.
#
# Shape of a context definition:
#
#    den.ctx.foobar = {
#      desc = "The {foo,bar} context";
#      conf = { foo, bar }: den.aspects.${foo}._.${bar};
#      includes = [ <parametric aspects for this context> ];
#      into = {
#        baz = { foo, bar }: lib.singleton { baz = 22; };
#      };
#    };
#
# A context type is callable (it is a functor):
#
#    aspect = den.ctx.foobar { foo = "hello"; bar = "world"; };
#
# ctxApply produces an aspect that includes: owned configs from the
# context type itself, the located aspect via conf, and all recursive
# transformations via into.
#
# Transformations have type: source -> [ target ]. This allows fan-out
# (one host producing many { host, user } pairs via map) and conditional
# propagation (lib.optional for detection gates like hm-host).
#
# den.default is an alias for den.ctx.default. Every context type
# transforms into default, so den.default.includes runs at every
# pipeline stage. Use take.exactly to restrict matching.
#
# See os.nix, defaults.nix and provides/home-manager/ for built-in
# context types.
{ den, lib, ... }:
let
  inherit (den.lib) parametric take;
  inherit (den.lib.aspects.types) providerType;

  ctxType = lib.types.submodule {
    freeformType = lib.types.lazyAttrsOf lib.types.deferredModule;
    options = {
      desc = lib.mkOption {
        description = "Context description";
        type = lib.types.str;
        default = "";
      };
      conf = lib.mkOption {
        description = "Obtain a configuration aspect for context";
        type = lib.types.functionTo providerType;
        default = { };
      };
      into = lib.mkOption {
        description = "Context transformations";
        type = lib.types.lazyAttrsOf (lib.types.functionTo (lib.types.listOf lib.types.raw));
        default = { };
      };
      includes = lib.mkOption {
        description = "List of parametric aspects to include for this context";
        type = lib.types.listOf providerType;
        default = [ ];
      };
      __functor = lib.mkOption {
        description = "Apply context. Returns a aspect with all dependencies.";
        type = lib.types.functionTo (lib.types.functionTo providerType);
        readOnly = true;
        internal = true;
        visible = false;
        default = ctxApply;
      };
    };
  };

  cleanCtx =
    ctx:
    builtins.removeAttrs ctx [
      "desc"
      "conf"
      "into"
      "__functor"
    ];

  # Given a context, returns an aspect that also includes
  # the result of all context propagation.
  ctxApply =
    self: ctx:
    let
      myself = parametric.fixedTo ctx (cleanCtx self);
      located = self.conf ctx;
      adapted = lib.mapAttrsToList (name: into: map den.ctx.${name} (into ctx)) self.into;
    in
    {
      includes = lib.flatten [
        myself
        located
        adapted
      ];
    };

in
{
  options.den.ctx = lib.mkOption {
    default = { };
    type = lib.types.lazyAttrsOf ctxType;
  };
}
