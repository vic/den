{ den, ... }:
{
  den.aspects.desktop-gdm = {
    includes = with den.aspects; [ workstation ];
    meta.adapter =
      inherited: den.lib.aspects.adapters.substituteAspect den.aspects.regreet den.aspects.gdm inherited;
  };
}
