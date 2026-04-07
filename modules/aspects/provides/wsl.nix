{
  den,
  lib,
  inputs,
  ...
}:
let
  description = ''
    Enables WSL support on NixOS. Using NixOS-WSL project.

    # Requirements

    - have an inputs.nixos-wsl input or specify host.wsl.module.
    - host.class is "nixos"

    # Usage

    On a single host:

       den.hosts.x86_64-linux.igloo.wsl.enable = true;

    On ALL hosts (works only on nixos class hosts):

       den.schema.host.wsl.enable = true;
  '';

  ctx.host.into.wsl-host =
    { host }: lib.optional (host.class == "nixos" && host.wsl.enable) { inherit host; };

  ctx.wsl-host.provides.wsl-host =
    { host }:
    {
      inherit description;
      ${host.class} = {
        imports = [ host.wsl.module ];
        wsl.enable = true;
      };
      includes = [ (fwd host) ];
    };

  fwd =
    host:
    { class, aspect-chain }:
    den._.forward {
      each = lib.singleton true;
      fromClass = _: "wsl";
      intoClass = _: host.class;
      intoPath = _: [ "wsl" ];
      fromAspect = _: lib.head aspect-chain;
      guard = { options, ... }: options ? wsl;
    };

  hostConf.options.wsl = {
    enable = lib.mkEnableOption "Enable WSL on this host";
    module = lib.mkOption {
      description = "The NixOS-WSL module";
      type = lib.types.deferredModule;
      defaultText = lib.literalExpression "inputs.nixos-wsl.nixosModules.default";
      default = inputs.nixos-wsl.nixosModules.default;
    };
  };

in
{
  den.ctx = ctx;
  den.schema.host.imports = [ hostConf ];
}
