{ den, ... }:
{
  # NOTE: perHost aspects resolve correctly in adapters.trace (see test
  # test-perHost-visible-in-trace) but may not appear in traces generated
  # via den.ctx.host due to how the context pipeline handles parametric aspects.
  den.aspects.mail = den.lib.perHost (
    { host }:
    {
      nixos.services.postfix = {
        enable = true;
        hostname = host.hostName;
      };
    }
  );
}
