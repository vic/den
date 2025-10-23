# create aspect dependencies from hosts/users
{
  lib,
  config,
  inputs,
  ...
}:
let
  hosts = lib.attrValues config.den.hosts;

  hostAspect =
    host:
    { aspects, ... }:
    {
      ${host.aspect} = {
        description = lib.mkDefault "Host ${host.hostName}";
        includes = [ (aspects.default.host host) ];
        ${host.class} = { };
      };
    };

  hostUserAspect =
    host: user:
    { aspects, ... }:
    {
      ${user.aspect} = {
        description = lib.mkDefault "User ${user.userName}";
        includes = [ (aspects.default.user host user) ];
        ${user.class} = { };
      };
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
          includes = [ (_: {class, ...}: aspect.${class} or {}) ];
          __functor = _: host: x: {
            includes = lib.map (f: f host x) aspect.includes;
          };
        };
      default.user =
        { aspect, ... }:
        {
          includes = [ (_: _: {class, ...}: aspect.${class} or {}) ];
          __functor = _: host: user: x: {
            includes = lib.map (f: f host user x) aspect.includes;
          };
        };
    }
  ];

  fa-types = inputs.flake-aspects.lib.types lib;
  defaultOption =
    description:
    lib.mkOption {
      inherit description;
      default = { };
      type = fa-types.aspectSubmoduleType;
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
