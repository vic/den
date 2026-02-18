---
title: Community
description: Get help, share your work, and contribute to Den.
---

## Get Support

- [GitHub Discussions](https://github.com/vic/den/discussions) — ask questions, share ideas
- [Zulip Chat](https://oeiuwq.zulipchat.com/#narrow/channel/548534-den) — real-time help
- [Matrix Channel](https://matrix.to/#/#den-lib:matrix.org) — chat with the community

Everyone is welcome. The only rule: be mindful and respectful.

## Real-World Examples

- [`vic/vix`](https://github.com/vic/vix) — Den author's personal infra
- [`quasigod.xyz/nixconfig`](https://tangled.org/quasigod.xyz/nixconfig)
- [GitHub Search](https://github.com/search?q=vic%2Fden+language%3ANix&type=code) — find more

## Contributing

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

## Ecosystem

- [flake-aspects](https://github.com/vic/flake-aspects) — aspect composition library
- [import-tree](https://github.com/vic/import-tree) — recursive module imports
- [denful](https://github.com/vic/denful) — community aspect distribution
- [dendrix](https://dendrix.oeiuwq.com/) — index of dendritic aspects
- [Dendritic Design](https://github.com/mightyiam/dendritic) — the pattern that inspired Den

## Sponsor

Den is made with love by [vic](https://bsky.app/profile/oeiuwq.bsky.social).

If you find Den useful, consider [sponsoring](https://github.com/sponsors/vic).

> *Quaerendo Invenietis* — Seek and ye shall find.
