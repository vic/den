{ den, lib, ... }:
let
  description = ''
    The `os` class is a convenience for settings that should be forwarded
    into both `nixos` and `darwin` classes.

    This class is enabled by default.

    # Usage

      den.aspects.my-host = {
        os.networking.hostName = "foo";
      };

  '';

  os-class =
    { class, aspect-chain }:
    den.provides.forward {
      each = [
        "nixos"
        "darwin"
      ];
      fromClass = _: "os";
      intoClass = lib.id;
      intoPath = _: [ ];
      fromAspect = _: lib.head aspect-chain;
    };

in
{
  den.ctx.default.includes = [ os-class ];
  den.schema.aspect.options.os = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
  };
}
