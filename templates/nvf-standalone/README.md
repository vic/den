# NVF Standalone in Den

This is an example showing how to create custom
configurations outside NixOS/Darwin/HM in Den.

For Demo purposes this template configures
an [NVF Standalone](https://nvf.notashelf.dev/index.html#ch-standalone-installation) instance using Den aspects
and forwarding classes.

It exposes the standalone nvf as `my-neovim` app,
runnable with:

```console
nix run .#my-neovim
```
