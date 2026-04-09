{ den, ... }:
{
  den.aspects.relay.includes = with den.aspects; [
    server
    mail
  ];
}
