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
        includes = [ (aspects.defaults.host host) ];
        ${host.class} = { };
      };
    };

  hostIncludesUser =
    host: user:
    { aspects, ... }:
    {
      ${user.aspect} = {
        description = lib.mkDefault "User ${user.userName}";
        includes = [ (aspects.defaults.user host user) ];
        ${user.class} = { };
      };
    };

  deps = lib.map (host: [
    (hostAspect host)
    (lib.map (hostIncludesUser host) (lib.attrValues host.users))
  ]) hosts;

  defaults = [
    {
      defaults.host =
        { aspect, ... }:
        {
          __functor = _: host: x: {
            includes = lib.map (f: f host x) aspect.includes;
          };
        };
      defaults.user =
        { aspect, ... }:
        {
          __functor = _: host: user: x: {
            includes = lib.map (f: f host user x) aspect.includes;
          };
        };
    }
  ];

  fa-types = inputs.flake-aspects.lib.types lib;
  defaultsOption =
    description:
    lib.mkOption {
      inherit description;
      default = { };
      type = fa-types.aspectSubmoduleType;
    };

in
{
  config.flake.aspects = lib.mkMerge (lib.flatten (defaults ++ deps));

  options.flake.aspects.defaults = lib.mkOption {
    description = "defaults";
    default = { };
    type = lib.types.submodule {
      options.host = defaultsOption "defaults for hosts";
      options.user = defaultsOption "defaults for users";
    };
  };
}
