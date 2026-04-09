{ den, ... }:
{
  # Server with nginx-exporter excluded — verifies excluded providers
  # don't forward their config into the build.
  den.aspects.web-server = {
    includes = with den.aspects; [ server ];
    meta.adapter = inherited:
      den.lib.aspects.adapters.excludeAspect den.aspects.monitoring._.nginx-exporter inherited;
  };
}
