{
  den,
  lib,
  config,
  inputs,
  ...
}:
let
  # extends den.schema.host with MicroVM specific options
  extendHostSchema =
    { host, ... }:
    {
      options.microvm.module = lib.mkOption {
        description = "MicroVM microvm.nix module";
        type = lib.types.deferredModule;
        default = inputs.microvm."${host.class}Modules".microvm;
      };

      options.microvm.hostModule = lib.mkOption {
        description = "MicroVM host.nix module";
        type = lib.types.deferredModule;
        default = inputs.microvm."${host.class}Modules".host;
      };

      # Declarative Guest VMs built with Host.
      options.microvm.guests = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        defaultText = lib.literalExpression "[ ]";
        description = ''
          Guest MicroVMs.
          Value is a list of Den hosts: [ den.hosts.x86_64-linux.foo-microvm ]

          When non empty, Host imports <microvm>/host.nix module
          and starts our Den microvm-host context pipeline.

          See: https://microvm-nix.github.io/microvm.nix/host.html
               https://microvm-nix.github.io/microvm.nix/declarative.html
        '';
      };

      options.microvm.sharedNixStore = lib.mkEnableOption "Auto share nix store from host";
      config.microvm.sharedNixStore = lib.mkDefault true;
    };

  # transition a NixOS host into a MicroVM host (only if it has guest microvms)
  ctx.host.into.microvm-host = { host }: lib.optional (host.microvm.guests != [ ]) { inherit host; };

  # aspect configuring a MicroVM host. imports the microvm host.nix module.
  ctx.microvm-host.provides.microvm-host =
    { host }:
    {
      ${host.class}.imports = [ host.microvm.hostModule ];
    };

  # transition from microvm host into each microvm guest
  ctx.microvm-host.into.microvm-guest = { host }: map (vm: { inherit host vm; }) host.microvm.guests;

  # aspect configuring a guest vm at the host level (Declarative in MicroVM parlance)
  # See: https://microvm-nix.github.io/microvm.nix/declarative.html
  ctx.microvm-host.provides.microvm-guest =
    { host }:
    { host, vm }:
    {
      includes =
        let
          sharedNixStore = lib.optionalAttrs host.microvm.sharedNixStore {
            ${host.class}.microvm.vms.${vm.name}.config.microvm.shares = [
              {
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                tag = "ro-store";
                proto = "virtiofs";
              }
            ];
          };

          # forwards guest nixos configuration into host: microvm.vms.<vm-name>.config
          osFwd = den.provides.forward {
            each = lib.singleton true;
            fromClass = _: vm.class;
            intoClass = _: host.class;
            intoPath = _: [
              "microvm"
              "vms"
              vm.name
              "config"
            ];
            # calling host-pipeline ensure all Den features supported on guest
            fromAspect = _: den.ctx.host { host = vm; };
          };

          # forwards guest microvm class into host: microvm.vms.<vm-name>
          microvmClass = den.provides.forward {
            each = lib.singleton true;
            fromClass = _: "microvm";
            intoClass = _: host.class;
            intoPath = _: [
              "microvm"
              "vms"
              vm.name
            ];
            fromAspect = _: vm.aspect;
          };

        in
        [
          sharedNixStore
          osFwd
          microvmClass
        ];
    };

in
{
  den.ctx = ctx;
  den.schema.host.imports = [ extendHostSchema ];
}
