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

# den - Re-usable Dendritic Nix configurations. [See MOTIVATION](https://den.oeiuwq.com/motivation/)

> den and [vic](https://bsky.app/profile/oeiuwq.bsky.social)'s [dendritic libs](https://vic.github.io/dendrix/Dendritic-Ecosystem.html#vics-dendritic-libraries) made for you with Love++ and AI--. If you like my work, consider [sponsoring](https://github.com/sponsors/vic)

<table>
<tr>
<td>
<div style="max-width: 320px;">

<img width="300" height="300" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" />

- [Dendritic](https://den.oeiuwq.com/explanation/core-principles/): **same** concern across **different** Nix classes.

- [Flake optional](https://den.oeiuwq.com/guides/no-flakes/). Works with _stable_/_unstable_ Nix and with/without flake-parts.

- Create [DRY](modules/aspects/provides/unfree/unfree.nix) & [`class`-generic](modules/aspects/provides/primary-user.nix) modules.

- [Parametric](https://den.oeiuwq.com/explanation/parametric/) over `host`/`home`/`user`.

- Context-aware [dependencies](https://den.oeiuwq.com/explanation/context-system/) with `host<->user` [bidirectional](https://den.oeiuwq.com/guides/bidirectional/) contributions.

- [Share](https://den.oeiuwq.com/guides/namespaces/) aspects across systems & repos.

- [Routable](templates/example/modules/aspects/eg/routes.nix) configurations.

- Custom [factories](https://github.com/vic/den/blob/f5c44098e4855e07bf5cbcec00509e75ddde4220/templates/ci/modules/homes.nix#L20) for any Nix `class`.

- Use different `stable`/`unstable` input channels per host.

- Freeform `host`/`user`/`home` [schemas](https://den.oeiuwq.com/reference/schema/) (no `specialArgs`) with [base](https://github.com/vic/den/pull/119) modules.

- Multi-platform, multi-tenant hosts.

- [Batteries](https://den.oeiuwq.com/guides/batteries/): Opt-in, replaceable aspects.

- Opt-in [`<angle/brackets>`](https://den.oeiuwq.com/guides/angle-brackets/) aspect resolution.

- _Incremental_ adoption on [exising](https://github.com/vic/den/discussions/151#discussioncomment-15797741) flakes, and _unobstrusive_ [migration](https://den.oeiuwq.com/guides/migrate/) plan.

- Features [tested](templates/ci).

- REPL [friendly](https://github.com/vic/den/blob/f5c44098e4855e07bf5cbcec00509e75ddde4220/templates/bogus/modules/bug.nix#L34) [debugging](https://den.oeiuwq.com/guides/debug/).

Need more **batteries**? See [vic/denful](https://github.com/vic/denful).

**❄️ Try it now!**

Launch our template VM:

```console
nix run github:vic/den
```

Or, initialize a project:

```console
nix flake init -t github:vic/den
nix flake update den
nix run .#vm
```

**Real-world examples for inspiration**

- [`vic/vix`](https://github.com/vic/vix)
- [`quasigod.xyz/nixconfig`](https://tangled.org/quasigod.xyz/nixconfig)
- [GitHub Search](https://github.com/search?q=vic%2Fden+language%3ANix&type=code).

**Available templates**

- [`default`](templates/default) batteries-included layout.
- [`minimal`](templates/minimal) minimalistic flake.
- [`noflake`](templates/noflake) no flakes, no flake-parts, user nix-maid.
- [`example`](templates/example) examples.
- [`ci`](templates/ci) tests for all features.
- [`bogus`](templates/bogus) reproduce and report bugs.

</div>
</td>
<td>

### Den fundamental idea

> Configurations that can be applied to multiple host/user combinations.
> The [`__functor`](https://den.oeiuwq.com/explanation/aspects/) pattern makes aspects parametric.

<details>

<summary>
  Den is about propagating context to produce configs.
</summary>

```nix
# context => aspect
{ host, user, ... }@context: {
  # any Nix configuration classes
  nixos = { };
  darwin = { };
  homeManager = { };
  # supports conditional includes that inspect context
  # unlike nix-module imports
  includes = [ ];
}
```

You first define which [Hosts, Users](templates/ci/modules/hosts.nix)
and [Homes](templates/ci/modules/homes.nix) exist
using freeform-attributes or base-modules.

```nix
{
  # isWarm or any other freeform attr
  den.hosts.x86_64-linux.igloo.isWarm = true;
}
```

Then, you write functions from context `host`/`user` to configs.

```nix
{
  den.aspects.heating = { host, user, ... }: {
    nixos = { ... }; # depends on host.isWarm, etc.
    homeManager = { ... };
  };

  # previous aspect can be included on any host
  #   den.aspects.igloo.includes = [ den.aspects.heating ];
  # or by default in all of them
  #   den.default.includes = [ den.aspects.heating ];
}
```

This way, configurations are truly re-usable,
as they are nothing more than functions of the
particularities of the host or its users.

</details>

### Library vs framework

Den works as both a **library** and a **framework**:

- **Library** — a domain‑agnostic, context‑aware, aspect‑oriented API you can import and extend; build custom context pipelines and parametric aspects for anything Nix configurable.
- **Framework** — batteries, ready-made schemas (`host`/`user`/`home`) and integrations tailored for NixOS/Darwin/home-manager configurations.

Den is independent and extensible — you can use only the library pieces, or adopt the framework batteries for faster NixOS/Darwin setups. See the full explanation: https://den.oeiuwq.com/explanation/library-vs-framework/

### Code example

Schema based hosts/users/homes entities (see [`_types.nix`](modules/_types.nix)).

```nix
# modules/hosts.nix
{
  # same vic home-manager aspect shared
  # on laptop, macbook and standalone-hm
  den.hosts.x86_64-linux.lap.users.vic = {};
  den.hosts.aarch64-darwin.mac.users.vic = {};
  den.homes.aarch64-darwin.vic = {};
}
```

```console
$ nixos-rebuild  switch --flake .#lap
$ darwin-rebuild switch --flake .#mac
$ home-manager   switch --flake .#vic
```

Any module can contribute configurations to [aspects](https://github.com/vic/flake-aspects).

```nix
# modules/my-laptop.nix
{ den, inputs, ... }: {

  # Example: enhance the my-laptop aspect.
  # This can be done from any file, multiple times.
  den.aspects.my-laptop = {

    # this aspect includes configurations
    # available from other aspects
    includes = [
      # your own parametric aspects
      den.aspects.workplace-vpn
      # den's opt-in batteries includes.
      den.provides.home-manager
    ];

    # any file can contribute to this aspect, so
    # best practice is to keep concerns separated,
    # each on their own file, instead of having huge
    # modules in a single file:

    # any NixOS configuration
    nixos  = { pkgs, ... }: {
      # A nixos class module, see NixOS options.
      # import third-party NixOS modules
      imports = [
        inputs.disko.nixosModules.disko
      ];
      disko.devices = { /* ... */ };
    };
    # any nix-darwin configuration
    darwin = {
      # import third-party Darwin modules
      imports = [
        inputs.nix-homebrew.darwinModules.nix-homebrew
      ];
      nix-homebrew.enableRosetta = true;
    };
    # For all users of my-laptop
    homeManager.programs.vim.enable = true;

  };
}
```

```nix
# modules/vic.nix
{ den, ... }: {
  den.aspects.vic = {
    homeManager = { pkgs, ... }: { /* ... */ };
    # User contribs to host
    nixos.users.users = {
      vic.description = "oeiuwq";
    };
    includes = [
      den.aspects.tiling-wm
      den.provides.primary-user
    ];
  };
}
```

</td>
</tr>
</table>

You are done! You know everything to start creating configurations with `den`.

Feel free to to **explore** the codebase, particularly our [included batteries](modules/aspects/provides) and [tests](templates/ci).

## Learn more at our [documentation website](https://den.oeiuwq.com)

Join our [community discussion](https://github.com/vic/den/discussions).
