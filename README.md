<p align="right">
  <a href="https://github.com/sponsors/vic"><img src="https://img.shields.io/badge/sponsor-vic-white?logo=githubsponsors&logoColor=white&labelColor=%23FF0000" alt="Sponsor Vic"/>
  </a>
  <a href="https://github.com/vic/den/releases"><img src="https://img.shields.io/github/v/release/vic/den?style=plastic&logo=github&color=purple"/></a>
  <a href="https://vic.github.io/dendrix/Dendritic-Ecosystem.html#vics-dendritic-libraries"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
</p>

# den - an aspect-oriented approach to Dendritic Nix configurations.

> den and [vic](https://bsky.app/profile/oeiuwq.bsky.social)'s [dendritic libs](https://vic.github.io/dendrix/Dendritic-Ecosystem.html#vics-dendritic-libraries) made for you with Love++ and AI--. If you like my work, consider [sponsoring](https://github.com/sponsors/vic)

<table>
<tr>
<td>
<div style="max-width: 320px;">

<img width="300" height="300" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" />

- Dendritic: each module configures **same** concern over **different** Nix classes.

- Create [DRY](modules/aspects/provides/unfree.nix) & [`class`-generic](modules/aspects/provides/primary-user.nix) modules.

- [Parametric](modules/aspects/provides/define-user.nix) over `host`/`home`/`user`.

- [Share](templates/default/modules/namespace.nix) aspects across systems & repos.

- Context-aware [dependencies](modules/aspects/dependencies.nix): user/host contributions.

- [Routable](templates/default/modules/aspects/eg/routes.nix) configurations.

- Custom factories for any Nix `class`.

- Use `stable`/`unstable` channels per config.

- Freeform `host`/`user`/`home` [schemas](modules/_types.nix) (no `specialArgs`).

- Multi-platform, multi-tenant hosts.

- [Batteries](modules/aspects/provides/): Opt-in, replaceable aspects.

- Opt-in [`<angle/brackets>`](https://vic.github.io/den/angle-brackets.html) aspect resolution.

- Templates [tested](templates/default/modules/tests.nix) along [examples](templates/examples/modules/_example/ci).

- Concepts [documented](https://vic.github.io/den).

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

- [`vic/vix`](https://github.com/vic/vix/tree/den)
- [`belsanti.xyz/nixconfig`](https://tangled.org/belsanti.xyz/nixconfig/tree/den)
- [GitHub Search](https://github.com/search?q=vic%2Fden+language%3ANix&type=code).

**Available templates**

- [`default`](templates/default) batteries-included layout.
- [`minimal`](templates/minimal) truly minimalistic start.
- [`examples`](templates/examples) tests for all features.
- [`bogus`](templates/bogus) reproduce and report bugs.

</div>
</td>
<td>

🏠 Define [Hosts, Users](templates/examples/modules/_example/hosts.nix) & [Homes](templates/examples/modules/_example/homes.nix) concisely.

See schema in [`_types.nix`](modules/_types.nix).

```nix
# modules/hosts.nix
{
  # same home-manager vic configuration
  # over laptop, macbook and standalone-hm
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

🧩 [Aspect-oriented](https://github.com/vic/flake-aspects) incremental features. ([example](templates/default/modules/den.nix))

Any module can contribute configurations to aspects.

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
    nixos  = {
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

# modules/vic.nix
{ den, ... }: {
  den.aspects.vic = {
    homeManager = { /* ... */ };
    # User contribs to host
    nixos.users.users = {
      vic.description = "oeiuwq";
    };
    includes = [
      den.aspects.tiling-wm
      den._.primary-user
    ];
  };
}
```

</td>
</tr>
</table>

You are done! You know everything to start creating configurations with `den`.

Feel free to to **explore** the codebase, particularly our [included batteries](modules/aspects/provides) and [tests](templates/examples/modules/_example/ci).

## Learn more at our [documentation website](https://vic.github.io/den)

Join our [community discussion](https://github.com/vic/den/discussions).
