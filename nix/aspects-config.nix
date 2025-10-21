# create aspect dependencies from hosts/users
{ lib, config, ... }:
let
  hosts = lib.attrValues config.den.hosts;

  hostAspect =
    host:
    { aspects, ... }:
    {
      ${host.aspect} = {
        description = lib.mkDefault "Host ${host.hostName}";
        includes = [ aspects.${host.class} ];
        ${host.class} = { };
      };
      ${host.class}.${host.class} = { };
    };

  hostUsers = host: lib.attrValues host.users;

  hostIncludesUser =
    host: user:
    { aspects, ... }:
    {
      ${host.aspect} = {
        includes = [ aspects.${user.aspect} ];
      };
      ${user.aspect} = {
        description = lib.mkDefault "User ${user.userName}";
        ${user.class} = { };
        ${host.class} = { };
      };
    };

  hmUsers = host: lib.filter (u: u.class == "homeManager") (hostUsers host);
  anyHm = host: lib.length (hmUsers host) > 0;
  hostHomeManager =
    host:
    { aspects, ... }:
    {
      ${host.aspect}.includes = [ aspects.homeManager ];
    };
  homeManager.homeManager.description = "home manager aspect";

  deps = lib.map (host: [
    (hostAspect host)
    (lib.map (hostIncludesUser host) (hostUsers host))
    (lib.optionals (anyHm host) [
      (hostHomeManager host)
      homeManager
    ])
  ]) hosts;

in
{
  flake.aspects = lib.mkMerge (lib.flatten deps);
}
