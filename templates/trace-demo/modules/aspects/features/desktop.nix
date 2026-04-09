{ den, ... }:
{
  den.aspects.desktop = {
    includes = with den.aspects; [ regreet ];
    nixos.services.xserver.enable = true;
  };
}
