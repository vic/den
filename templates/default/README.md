# Getting Started Guide

Steps you can follow after cloning this template:

- Be sure to read the [den documentation](https://vic.github.io/den)

- Update den input.

```console
nix flake update den
```

- Run checks to test everything works.

```console
nix flake check
```

- Read [modules/den.nix](modules/den.nix) where hosts and homes definitions are for this example.

- Read [modules/namespace.nix](modules/namespace.nix) where a new `eg` (an example) aspects namespace is created.

- Read [modules/aspects/igloo.nix](modules/aspects/igloo.nix) where the `igloo` host is configured.

- Read [modules/aspects/alice.nix](modules/aspects/alice.nix) where the `alice` user is configured.

- Run the VM.

```console
nix run .#vm
```

- Edit and run VM loop.

Feel free to add more aspects, organize things to your liking.
