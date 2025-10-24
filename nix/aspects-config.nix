# create aspect dependencies from hosts/users
{
  lib,
  config,
  inputs,
  ...
}:
let
  hosts = lib.flatten (lib.map lib.attrValues (lib.attrValues config.den));

  hostAspect =
    host:
    { aspects, ... }:
    {
      ${host.aspect} = {
        includes = [ (aspects.default.host { inherit host; }) ];
        ${host.class} = { };
      };
    };

  emptyHostUserProvider =
    # deadnix: skip
    { host, user }: _: { };

  hostUserAspect =
    host: user:
    { aspects, ... }:
    let
      context = { inherit host user; };
      hostUserProvider = aspects.${user.aspect}.provides.${host.aspect} or emptyHostUserProvider;
    in
    {
      ${user.aspect} = {
        ${user.class} = { };
        includes = [ (aspects.default.user context) ];
      };

      ${host.aspect}.includes = [ (hostUserProvider context) ];
    };

  deps = lib.map (host: [
    (hostAspect host)
    (lib.map (hostUserAspect host) (lib.attrValues host.users))
  ]) hosts;

  defaults = [
    {
      default.host =
        { aspect, ... }:
        {
          __functor =
            _:
            { host }:
            { class, ... }:
            {
              name = "(default.host ${host.name})";
              includes = lib.map (f: f { inherit host; }) aspect.includes;
              ${class} = aspect.${class} or { };
            };
        };
      default.user =
        { aspect, ... }:
        {
          __functor =
            _:
            { host, user }:
            { class, ... }:
            {
              name = "(default.user ${host.name} ${user.name})";
              includes = lib.map (f: f { inherit host user; }) aspect.includes;
              ${class} = aspect.${class} or { };
            };
        };
    }
  ];

  aspect-types = inputs.flake-aspects.lib.types lib;
  defaultOption =
    description:
    lib.mkOption {
      inherit description;
      default = { };
      type = aspect-types.aspectSubmodule;
    };

in
{
  config.flake.aspects = lib.mkMerge (lib.flatten (defaults ++ deps));

  options.flake.aspects.default = lib.mkOption {
    description = "defaults";
    default = { };
    type = lib.types.submodule {
      options.host = defaultOption "defaults for hosts";
      options.user = defaultOption "defaults for users";
    };
  };
}
