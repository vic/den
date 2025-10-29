{ inputs, lib, ... }:
let

  # set host static default values directly by class:
  #
  #    den.aspects.default.host = {
  #      nixos  = ...;
  #      darwin = ...;
  #    }
  #
  # or register a function that takes the { host } param:
  #
  #    den.aspects.default.host.includes = [ aspectByHost ];
  #    aspectByHost = { host }: { class, aspect-chain }: {
  #      nixos  = ...;
  #      darwin = ...;
  #    }
  default.host =
    { aspect, ... }:
    {
      __functor =
        _:
        { host }:
        { class, ... }:
        {
          name = "(default.host ${host.name})";
          includes = map (f: f { inherit host; }) aspect.includes;
          ${class} = aspect.${class} or { };
        };
    };

  # set user static values directly by class:
  #
  #    den.aspects.default.user = {
  #      nixos  = ...;
  #      darwin = ...;
  #      homeManager = ...;
  #    }
  #
  # or register a function that takes the { host, user } param:
  #
  #    den.aspects.default.user.includes = [ aspectByUser ];
  #    aspectByUser = { host, user }: { class, aspect-chain }: {
  #      nixos  = ...;
  #      darwin = ...;
  #      homeManager = ...;
  #    }
  default.user =
    { aspect, ... }:
    {
      __functor =
        _:
        { host, user }:
        { class, ... }:
        {
          name = "(default.user ${host.name} ${user.name})";
          includes = map (f: f { inherit host user; }) aspect.includes;
          ${class} = aspect.${class} or { };
        };
    };

  # set home static values directly by class:
  #
  #    den.aspects.default.home = {
  #      homeManager = ...;
  #    }
  #
  # or register a function that takes the { home } param:
  #
  #    den.aspects.default.home.includes = [ aspectByHome ];
  #    aspectByHome = { home }: { class, aspect-chain }: {
  #      homeManager = ...;
  #    }
  default.home =
    { aspect, ... }:
    {
      __functor =
        _:
        { home }:
        { class, ... }:
        {
          name = "(default.home ${home.name})";
          includes = map (f: f { inherit home; }) aspect.includes;
          ${class} = aspect.${class} or { };
        };
    };

  aspect-option = import ./_aspect_option.nix { inherit inputs lib; };

in
{
  config.den = { inherit default; };
  options.den.default.host = aspect-option "host defaults";
  options.den.default.user = aspect-option "host user defaults";
  options.den.default.home = aspect-option "standalone home defaults";
}
