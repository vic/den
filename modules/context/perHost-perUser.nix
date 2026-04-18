{ lib, ... }:
let
  perHost =
    fn: lib.warn "den.lib.perHost is deprecated — use { host, ... }: ... directly as an include" fn;
  perUser = fn: lib.warn "den.lib.perUser is deprecated — use { host, user, ... }: ... directly" fn;
  perHome = fn: lib.warn "den.lib.perHome is deprecated — use { home, ... }: ... directly" fn;
in
{
  den.lib = { inherit perHome perUser perHost; };
}
