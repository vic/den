{ den, ... }:
let
  description = ''
    Enable Den bidirectionality: User takes configuration from Host.

    **REALLY** IMPORTANT: Read the documentation for den.ctx.user

    Consider as alternative den.provides.mutual-provider.
  '';
in
{
  den.provides.bidirectional = {
    inherit description;
    includes = [ den.ctx.user.provides.bidirectional ];
  };
}
