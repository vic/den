---
title: "Template: NVF Standalone"
description: Den based NVF configuration without NixOS
---

<Aside title="Source" icon="github">
[`templates/nvf-standalone`](https://github.com/vic/den/tree/main/templates/nvf-standalone)
</Aside>

The `nvf-standalone` template demonstrates how to use Den for
other configurations outside NixOS/nix-Darwin/HM. For demo
purposes this uses [NVF Standalone](https://nvf.notashelf.dev/#ch-standalone-installation) to configure a runnable `.#my-neovim` app.

## Initialize

```console
mkdir my-neovim && cd my-neovim
nix flake init -t github:vic/den#nvf-standalone
nix flake update den
nix run .#my-neovim
```

## Project Structure

```
flake.nix   # dependencies including NVF
modules/
  den.nix   # uses Den to expose a standalone neovim app.
```

Key points:
- **Runnable app** — exposes `.#my-neovim` app
- **Custom forward class** — uses a `vim` class that forwards to `nvf.config.vim`
- **Custom ctx** — shows how to use Den with custom context to resolve `nvf` module.

## Next Steps

- Read [NVF Documentation](https://nvf.notashelf.dev/)
