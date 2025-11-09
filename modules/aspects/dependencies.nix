{
  den,
  lib,
  ...
}:
let
  inherit (den.lib)
    owned
    statics
    parametric
    take
    ;

  dependencies = [
    ({ home, ... }: baseDeps home)
    ({ host, ... }: baseDeps host)
    ({ user, ... }: baseDeps user)
    (os osIncludesFromUsers)
    (hm hmIncludesFromHost)
  ];

  # deadnix: skip # exact { OS } to avoid recursion
  os = fn: { OS, ... }@ctx: take.exactly ctx fn;
  # deadnix: skip # exact { HM } to avoid recursion
  hm = fn: { HM, ... }@ctx: take.exactly ctx fn;

  baseDeps =
    from:
    let
      exists = from ? aspect && builtins.hasAttr from.aspect den.aspects;
      aspect = den.aspects.${from.aspect};
    in
    {
      includes = lib.optionals exists [
        (statics den.default)
        (statics aspect)
        (owned den.default)
        (owned aspect)
      ];
    };

  osIncludesFromUsers =
    { OS }:
    let
      inherit (OS) host;
      users = builtins.attrValues host.users;
      userDeps = user: parametric { inherit OS user host; } den.aspects.${user.aspect};
      userContribs.includes = map userDeps users;
      hostDeps = user: parametric { inherit user host; } den.aspects.${host.aspect};
      hostContribs.includes = map hostDeps users;
    in
    {
      includes = [
        hostContribs
        userContribs
      ];
    };

  hmIncludesFromHost =
    { HM }:
    let
      inherit (HM) user host;
      userDeps = parametric { inherit HM user host; } den.aspects.${user.aspect};
      hostDeps = parametric { inherit HM user host; } den.aspects.${host.aspect};
    in
    {
      includes = [
        userDeps
        hostDeps
      ];
    };
in
{
  den.default.includes = dependencies;
}
