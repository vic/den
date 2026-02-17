
{
  inputs,
  den,
  lib,
  ...
}:
let

  description = ''
    Enables hjem support on a host.

    Usage.
      
      den.aspects.my-host.includes = [ den._.hjem ]

    Expects `inputs.hjem` to exist.

    Enables the `hjem` class on user aspects, which are
    forwarded to OS level `hjem.users.<userName>`.
  '';

  hjem =
    { OS, host }:
    {
      ${host.class} = {
        imports = [ inputs.hjem."${host.class}Modules".default ];
      };
      includes = [ (fwd-hjem { inherit OS host; }) ];
    };

  fwd-hjem =
    { OS, host }:
    { class, aspect-chain }:
    den._.forward {
      each = lib.attrValues host.users;
      fromAspect = user: den.lib.parametric.fixedTo { inherit OS host user; } den.aspects.${user.aspect};
      fromClass = user: "hjem";
      intoClass = user: host.class;
      intoPath = user: [
        "hjem"
        "users"
        user.userName
      ];
    };

in
{
  den._.hjem= {
    inherit description;
    __functor = den.lib.take.exactly hjem;
  };
}
