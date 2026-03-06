# MicroVM in Den examples

There are two ways to run VMs:

## NixOS configuration MicroVM runner as package.

- Den example: [runnable-example.nix](./modules/runnable-example.nix)
- Den support: [microvm-runners.nix](./modules/microvm-runners.nix)

```console
nix run .#runnable-microvm
```

See https://microvm-nix.github.io/microvm.nix/packages.html

## MicroVM guests as part of a Host.

- Den example: [guests-example.nix](./modules/guests-example.nix)
- Den support: [microvm-integration.nix](./modules/microvm-integration.nix)

```console
nixos-rebuild build --flake .#server
```

See https://microvm-nix.github.io/microvm.nix/host.html\
https://microvm-nix.github.io/microvm.nix/declarative.html
