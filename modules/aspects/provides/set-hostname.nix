{ den, ... }:
{
  den.provides.set-hostname = den.lib.take.exactly (
    { host }:
    {
      description = ''
        Sets the system hostname as defined in `den.hosts`.

        Works on NixOS/Darwin/WSL.

        ## Usage

           den.defaults.includes = [ den._.set-hostname ];
      '';

      ${host.class}.networking.hostName = host.hostName;
    }
  );
}
