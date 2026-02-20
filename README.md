<p align="right">
  <a href="https://github.com/sponsors/vic"><img src="https://img.shields.io/badge/sponsor-vic-white?logo=githubsponsors&logoColor=white&labelColor=%23FF0000" alt="Sponsor Vic"/>
  </a>
  <a href="https://deepwiki.com/vic/den"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <a href="https://github.com/vic/den/releases"><img src="https://img.shields.io/github/v/release/vic/den?style=plastic&logo=github&color=purple"/></a>
  <a href="https://vic.github.io/dendrix/Dendritic-Ecosystem.html#vics-dendritic-libraries"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
</p>

# den - Context-aware Dendritic Nix configurations.

> den and [vic](https://bsky.app/profile/oeiuwq.bsky.social)'s [dendritic libs](https://vic.github.io/dendrix/Dendritic-Ecosystem.html#vics-dendritic-libraries) made for you with Love++ and AI--. If you like my work, consider [sponsoring](https://github.com/sponsors/vic)

> **Den as a Library**: domain-agnostic, context transformation pipelines that activate [flake-aspects](https://github.com/vic/flake-aspects).\
> **Den as Framework**: uses `den.lib` to provide batteries + `host`/`user`/`home` schemas for NixOS/nix-darwin/home-manager.\
> [Learn more →](https://den.oeiuwq.com/explanation/library-vs-framework/)

<table>
<tr>
<td>
<div style="max-width: 320px;">

<img width="300" height="300" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" />

- [Dendritic](https://den.oeiuwq.com/explanation/core-principles/): **same** concern, **different** Nix classes.
- [Flake optional](https://den.oeiuwq.com/guides/no-flakes/). Stable/unstable Nix, with/without flake-parts.
- [DRY](modules/aspects/provides/unfree/unfree.nix) & [`class`-generic](modules/aspects/provides/primary-user.nix) — [parametric](https://den.oeiuwq.com/explanation/parametric/) over `host`/`home`/`user`.
- Context-aware [dependencies](https://den.oeiuwq.com/explanation/context-system/); `host<->user` [bidirectional](https://den.oeiuwq.com/guides/bidirectional/) contributions.
- [Share](https://den.oeiuwq.com/guides/namespaces/) aspects across repos. [Routable](templates/example/modules/aspects/eg/routes.nix) configs.
- Custom [factories](https://github.com/vic/den/blob/f5c44098e4855e07bf5cbcec00509e75ddde4220/templates/ci/modules/homes.nix#L20) for any Nix `class`. Per-host `stable`/`unstable` channels.
- Freeform [schemas](https://den.oeiuwq.com/reference/schema/) (no `specialArgs`) with [base](https://github.com/vic/den/pull/119) modules.
- [Batteries](https://den.oeiuwq.com/guides/batteries/): opt-in, replaceable. [`<angle/brackets>`](https://den.oeiuwq.com/guides/angle-brackets/) resolution.
- [Incremental migration](https://den.oeiuwq.com/guides/migrate/). [Tested](templates/ci). REPL [debugging](https://den.oeiuwq.com/guides/debug/).

More batteries? → [vic/denful](https://github.com/vic/denful)

**❄️ Try it:**

```console
nix run github:vic/den
nix flake init -t github:vic/den && nix run .#vm
```

Templates: [default](templates/default) · [minimal](templates/minimal) · [noflake](templates/noflake) · [example](templates/example) · [ci](templates/ci) · [bogus](templates/bogus)

Examples: [`vic/vix`](https://github.com/vic/vix) · [`quasigod.xyz`](https://tangled.org/quasigod.xyz/nixconfig) · [GitHub Search](https://github.com/search?q=vic%2Fden+language%3ANix&type=code)

</div>
</td>
<td>

### Code example (OS configuration domain)

```nix
# hosts & homes have extensible schema types.
den.hosts.x86_64-linux.lap.users.vic = {};
den.hosts.aarch64-darwin.mac.users.vic = {};
den.homes.aarch64-darwin.vic = {};
```

```nix
# modules/my-laptop.nix
{ den, inputs, ... }: {
  den.aspects.my-laptop = {
    includes = [
      den.aspects.work-vpn
    ];
    # regular nixos/darwin modules or any other Nix class
    nixos  = { pkgs, ... }: {
       imports = [ inputs.disko.nixosModules.disko ];
    };
    darwin = { ... };
    homeManager.programs.vim.enable = true;
  };
}
```

```nix
# modules/vic.nix
{ den, ... }: {
  den.aspects.vic = {
    homeManager = { pkgs, ... }: ...;
    nixos.users.users.vic.description = "oeiuwq";
    includes = [
      den.aspects.tiling-wm
      den.provides.primary-user
    ];
  };
}
```

```console
$ nixos-rebuild switch --flake .#lap
$ darwin-rebuild switch --flake .#mac
$ home-manager   switch --flake .#vic
```

</td>
</tr>
</table>

[Documentation](https://den.oeiuwq.com) · [Batteries](modules/aspects/provides) · [Tests](templates/ci) · [Community](https://github.com/vic/den/discussions)
