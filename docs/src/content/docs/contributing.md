---
title: Contributing
description: Report bugs and contribute pull-requests
---

All contributions welcome. PRs are checked by CI.

### Run Tests

```console
nix flake check github:vic/checkmate --override-input target .
```

### Format Code

```console
nix run github:vic/checkmate#fmt --override-input target .
```

### Report Bugs

Use the `bogus` template to create a minimal reproduction:

```console
mkdir bogus && cd bogus
nix flake init -t github:vic/den#bogus
nix flake update den
nix flake check
```

Share your repository with us on [Discussions](https://github.com/vic/den/discussions).