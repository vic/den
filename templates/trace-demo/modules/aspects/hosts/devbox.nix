{ den, ... }:
{
  den.aspects.devbox = {
    includes = with den.aspects; [
      workstation
      server
    ];
    meta.adapter = inherited: den.lib.aspects.adapters.excludeAspect den.aspects.tailscale inherited;
  };
}
