{
  den,
  lib,
  inputs,
  ...
}:
let
  description = ''
    Detects hosts that have an HM supported OS and
    that have at least one user with ${hm-class} class.

    When this occurs it produces a context `den.ctx.hm-os`

    This `den.ctx.hm-os` context includes the OS-level
    homeManager module and is used by hm-integration.nix to then
    produce a `den.ctx.hm` for each user.

    This same context can be used to include aspects
    ONLY for hosts having HM enabled.

       den.ctx.hm-os.includes = [ den.aspects.foo ];
  '';

  hm-class = "homeManager";
  hm-os-classes = [
    "nixos"
    "darwin"
  ];
  hm-module = host: host.hm-module or inputs.home-manager."${host.class}Modules".home-manager;

  hm-detect =
    { host }:
    let
      is-os-supported = builtins.elem host.class hm-os-classes;
      has-hm-module = (host ? hm-module) || (inputs ? home-manager);
      hm-users = builtins.filter (u: u.class == hm-class) (lib.attrValues host.users);
      has-hm-users = builtins.length hm-users > 0;
      is-hm-host = is-os-supported && has-hm-users && has-hm-module;
    in
    lib.optional is-hm-host { inherit host; };

in
{
  den.ctx.host.into.hm-host = hm-detect;

  den.ctx.hm-host.description = description;
  den.ctx.hm-host._.hm-host =
    { host }:
    {
      ${host.class}.imports = [ (hm-module host) ];
    };
}
