{ inputs, den, ... }:
{
  systems = builtins.attrNames den.hosts;
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.igloo.users.tux = { };
  den.aspects.igloo = { };
}
