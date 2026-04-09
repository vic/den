{ den, __findFile, ... }:
{
  den.aspects.angle-brackets = {
    includes = [
      <den/primary-user>
      den.aspects.networking
      den.aspects.tailscale
      den.aspects.desktop
    ];
    meta.adapter = inherited: den.lib.aspects.adapters.excludeAspect den.aspects.tailscale inherited;
  };
}
