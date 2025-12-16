{
  den,
  ...
}:
let
  inherit (den.lib)
    owned
    statics
    take
    ;

  dependencies = [
    (take.exactly osDependencies)
  ];

  osDependencies =
    { OS, host }:
    {
      includes = [
        (owned den.default)
        (statics den.default)
        (owned OS)
        (statics OS)
        {
          includes =
            let
              users = builtins.attrValues host.users;
              contrib = osUserDependencies { inherit OS host; };
            in
            map contrib users;
        }
      ];
    };

  osUserDependencies =
    { OS, host }:
    user:
    let
      USR = den.aspects.${user.aspect};
    in
    {
      includes = [
        (owned USR)
        (statics USR)
        (USR { inherit OS host user; })
      ];
    };

in
{
  den.default.includes = dependencies;
}
