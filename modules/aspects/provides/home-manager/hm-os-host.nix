{ den, lib, ... }:
let
  description = ''
    This is a private aspect always included in den.default.

    This aspect detects hosts that have an HM supported OS and
    that have at least one user with ${hm-class} class.

    When this occurs it produces a context `HM-OS-HOST`
    that other host aspects can use.

    When the `den._.home-manager` aspect is enabled by the user,
    it reacts to this context and configures HM on the host.

    This same context can be used by other aspects to configure
    OS settings ONLY for hosts having HM enabled.
  '';

  hm-class = "homeManager";
  hm-os-classes = [
    "nixos"
    "darwin"
  ];

  hm-detect =
    { OS, host }:
    let
      is-os-supported = builtins.elem host.class hm-os-classes;
      hm-users = builtins.filter (u: u.class == hm-class) (lib.attrValues host.users);
      has-hm-users = builtins.length hm-users > 0;
      is-hm-host = is-os-supported && has-hm-users;
      ctx.HM-OS-HOST = { inherit OS host; };
    in
    if is-hm-host then OS ctx else { };

  aspect = {
    inherit description;
    __functor = _: den.lib.take.exactly hm-detect;
  };
in
{
  den.default.includes = [ aspect ];
}
