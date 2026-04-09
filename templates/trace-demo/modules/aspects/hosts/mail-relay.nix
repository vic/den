{ den, ... }:
{
  # Exclude by aspect reference — uses aspectPath to compare identity,
  # equivalent to the POC's host.excludes = [ <monitoring> ].
  den.aspects.mail-relay = {
    includes = with den.aspects; [ relay ];
    meta.adapter = inherited: den.lib.aspects.adapters.excludeAspect den.aspects.monitoring inherited;
  };
}
