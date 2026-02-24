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

<table>
<tr>
<td>
<div style="max-width: 320px;">

<img width="300" height="300" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" />

### [Documentation](https://den.oeiuwq.com)

### [Batteries](https://den.oeiuwq.com/guides/batteries/)

### [Tests as Code Examples](https://den.oeiuwq.com/tutorials/ci/)

### [Community](https://github.com/vic/den/discussions)

**Den as a [Library](https://den.oeiuwq.com/explanation/library-vs-framework/)**:

domain-agnostic, context transformation pipelines that activate [flake-aspects](https://github.com/vic/flake-aspects).

**Den as [Framework](https://den.oeiuwq.com/explanation/context-pipeline/)**:

uses `den.lib` to provide batteries + `host`/`user`/`home` schemas for NixOS/nix-darwin/home-manager.

### Templates:

[default](https://den.oeiuwq.com/tutorials/default/): +flake-file +flake-parts +home-manager

[minimal](https://den.oeiuwq.com/tutorials/minimal): +flakes -flake-parts -home-manager

[noflake](https://den.oeiuwq.com/tutorials/noflake): -flakes +npins +lib.evalModules +nix-maid

[example](https://den.oeiuwq.com/tutorials/example): cross-platform

[ci](https://den.oeiuwq.com/tutorials/ci): Each feature tested as code examples

[bogus](https://den.oeiuwq.com/tutorials/bogus): Isolated test for bug reproduction

### Examples:

[`vic/vix`](https://github.com/vic/vix): author spends more time in Den itself (-flakes)

[`quasigod.xyz`](https://tangled.org/quasigod.xyz/nixconfig): beautiful organization (+flake-parts)

[GitHub Search](https://github.com/search?q=vic%2Fden+language%3ANix&type=code)

**❄️ Try it:**

```console
nix run github:vic/den
nix flake init -t github:vic/den && nix run .#vm
```

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
      den.aspects.vic._.conditional
    ];

    provides = {
      conditional = { host, user }:
        lib.optionalAttrs (host.hasX && user.hasY)  {
           nixos.imports = [
            inputs.someX.nixosModules.default
           ];
           nixos.someX.foo = user.someY;
        };
      };
    };
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
