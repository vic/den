{ inputs, lib, ... }:
let

  default.host =
    { aspect, ... }:
    {
      name = "<default.host>";
      provides.host.includes = [ ];
      provides.host.__functor =
        callbacks:
        { host }:
        {
          name = "<${aspect.name}.host.*>";
          includes = [ aspect ] ++ (map (f: f { inherit host; }) callbacks.includes);
        };
    };

  default.user =
    { aspect, ... }:
    {
      name = "<default.user>";
      provides.user.includes = [ ];
      provides.user.__functor =
        callbacks:
        { host, user }:
        {
          name = "<${aspect.name}.user.*>";
          includes = [ aspect ] ++ (map (f: f { inherit host user; }) callbacks.includes);
        };
    };

  default.home =
    { aspect, ... }:
    {
      name = "<default.home>";
      provides.home.includes = [ ];
      provides.home.__functor =
        callbacks:
        { home }:
        {
          name = "<${aspect.name}.home.*>";
          includes = [ aspect ] ++ (map (f: f { inherit home; }) callbacks.includes);
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
