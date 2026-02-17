{
  inputs,
  den,
  lib,
  ...
}:
let

  description = ''
    Enables nix-maid support on a host.

    Usage.
      
      den.aspects.my-host.includes = [ den._.nix-maid ]

    Expects `inputs.nix-maid` to exist.

    Enables the `maid` class on user aspects, which are
    forwarded to OS level `users.users.<userName>.maid`.
  '';

  maid =
    { OS, host }:
    {
      # NOTE: nix-maid currently provides no darwin module
      ${host.class} = {
        imports = [ inputs.nix-maid.nixosModules.default ];
      };
      includes = [ (fwd-maid { inherit OS host; }) ];
    };

  fwd-maid =
    { OS, host }:
    { class, aspect-chain }:
    den._.forward {
      each = lib.attrValues host.users;
      fromAspect = user: den.lib.parametric.fixedTo { inherit OS host user; } den.aspects.${user.aspect};
      fromClass = user: "maid";
      intoClass = user: host.class;
      intoPath = user: [
        "users"
        "users"
        user.userName
        "maid"
      ];
    };

in
{
  den._.nix-maid = {
    inherit description;
    __functor = den.lib.take.exactly maid;
  };
}
