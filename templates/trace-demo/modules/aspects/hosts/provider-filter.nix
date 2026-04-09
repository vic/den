{ den, lib, ... }:
{
  # Exclude by provider prefix — filters all aspects originating from monitoring.
  den.aspects.provider-filter = {
    includes = with den.aspects; [ server ];
    meta.adapter =
      inherited:
      den.lib.aspects.adapters.filter (
        a: lib.take 1 (a.meta.provider or [ ]) != [ "monitoring" ]
      ) inherited;
  };
}
