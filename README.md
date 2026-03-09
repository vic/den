<p align="right">
  <a href="https://dendritic.oeiuwq.com/sponsor"><img src="https://img.shields.io/badge/sponsor-vic-white?logo=githubsponsors&logoColor=white&labelColor=%23FF0000" alt="Sponsor Vic"/>
  </a>
  <a href="https://deepwiki.com/vic/den"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <a href="https://github.com/vic/den/releases"><img src="https://img.shields.io/github/v/release/vic/den?style=plastic&logo=github&color=purple"/></a>
  <a href="https://dendritic.oeiuwq.com"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
</p>

# den - Aspect-oriented context-driven Dendritic Nix configurations.

> den and [vic](https://bsky.app/profile/oeiuwq.bsky.social)'s [dendritic libs](https://dendritic.oeiuwq.com) made for you with Love++ and AI--. If you like my work, consider [sponsoring](https://dendritic.oeiuwq.com/sponsor)

<table>
<tr>
<td>
<div style="max-width: 320px;">

<img width="300" height="300" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" />

# [Documentation](https://den.oeiuwq.com)

### [Core Principles](https://den.oeiuwq.com/explanation/core-principles/)

### [Custom Nix Classes](https://den.oeiuwq.com/guides/custom-classes/)

### [Homes Integration](https://den.oeiuwq.com/guides/home-manager/)

### [Batteries](https://den.oeiuwq.com/guides/batteries/)

### [Reference](https://den.oeiuwq.com/reference/ctx/)

### [Tests as Code Examples](https://den.oeiuwq.com/tutorials/ci/)

### [Motivation](https://den.oeiuwq.com/motivation/)

### [Community](https://den.oeiuwq.com/community/)

</div>
</td>
<td>

At its core, Den is a [library](https://den.oeiuwq.com/explanation/library-vs-framework/) built on [flake-aspects](https://github.com/vic/flake-aspects) for activating configuration-aspects via context-transformation pipelines.

On top of the library, Den provides a [framework](https://den.oeiuwq.com/explanation/context-pipeline/) for the NixOS/nix-Darwin/Home-Manager Nix domains.

Den embraces your Nix choices and does not impose itself. All parts of Den are optional and replaceable. Works with your current setup, with/without flakes, flake-parts or any other Nix module system.

### Templates:

[default](https://den.oeiuwq.com/tutorials/default/): +flake-file +flake-parts +home-manager

[minimal](https://den.oeiuwq.com/tutorials/minimal): +flakes -flake-parts -home-manager

[noflake](https://den.oeiuwq.com/tutorials/noflake): -flakes +npins +lib.evalModules +nix-maid

[microvm](https://den.oeiuwq.com/tutorials/microvm): MicroVM runnable-pkg and guests. custom ctx-pipeline.

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

</td>

</tr>
</table>

### Testimonials

> Den takes the Dendritic pattern to a whole new level, and I cannot imagine going back.\
> — `@adda` - Very early Den adopter after using Dendritic flake-parts and Unify.

> I’m super impressed with den so far, I’m excited to try out some new patterns that Unify couldn’t easily do.\
> — `@quasigod` - Author of [Unify](https://codeberg.org/quasigod/unify) dendritic-framework, on adopting Den.

> Massive work you did here!\
> — `@drupol` - Author of [“Flipping the Configuration Matrix”](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/#flipping-the-configuration-matrix) Dendritic blog post.

> Thanks for the awesome library and the support for non-flakes… it’s positively brilliant!. I really hope this gets wider adoption.\
> — `@vczf` - At [`#den-lib:matrix.org`](https://matrix.to/#/#den-lib:matrix.org) channel.

> Den is a playground for some very advanced concepts. I’m convinced that some of its ideas will play a role in future Nix areas. In my opinion there are some raw diamonds in Den.\
> — `@Doc-Steve` - Author of [Dendritic Design Guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)

## Code example (OS configuration domain)

### Defining hosts, users and homes.

```nix
den.hosts.x86_64-linux.lap.users.vic = {};
den.hosts.aarch64-darwin.mac.users.vic = {};
den.homes.aarch64-darwin.vic = {};
```

```console
$ nixos-rebuild switch --flake .#lap
$ darwin-rebuild switch --flake .#mac
$ home-manager   switch --flake .#vic
```

### Extensible Schemas for hosts, users and homes.

```nix
# extensible base modules for common, typed schemas
den.schema.user = { user, lib, ... }: {
  config.classes =
    if user.userName == "vic" then [ "hjem" "maid" ]
    else lib.mkDefault [ "homeManager" ];

  options.mainGroup = lib.mkOption { default = user.userName; };
};
```

### Dendritic Multi-Platform Hosts

```nix
# modules/my-laptop.nix
{ den, inputs, ... }: {
  den.aspects.my-laptop = {
    # re-usable configuration aspects. Den batteries and yours.
    includes = [ den.provides.hostname den.aspects.work-vpn ];

    # regular nixos/darwin modules or any other Nix class
    nixos  = { pkgs, ... }: { imports = [ inputs.disko.nixosModules.disko ]; };
    darwin = { pkgs, ... }: { imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ]; };

    # Custom Nix classes. `os` applies to both nixos and darwin. contributed by @Risa-G.
    # See https://den.oeiuwq.com/guides/custom-classes/#user-contributed-examples
    os = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.direnv ];
    };

    # host can contribute default home environments to all its users.
    homeManager.programs.vim.enable = true;
  };
}
```

### Multiple User Home Environments

```nix
# modules/vic.nix
{ den, ... }: {
  den.aspects.vic = {
    # supports multiple home environments, eg: for migrating from homeManager.
    homeManager = { pkgs, ... }: { };
    hjem.files.".envrc".text = "use flake ~/hk/home";
    maid.kconfig.settings.kwinrc.Desktops.Number = 3;

    # user can contribute OS-configurations to any host it lives on
    darwin.services.karabiner-elements.enable = true;

    # user class forwards into {nixos/darwin}.users.users.<userName>
    user = { pkgs, ... }: {
      packages = [ pkgs.helix ];
      description = "oeiuwq";
    };

    includes = [
      den.provides.primary-user        # re-usable batteries
      (den.provides.user-shell "fish") # parametric aspects
      den.aspects.tiling-wm            # your own aspects
      den.aspects.gaming.provides.emulators
    ];
  };
}
```

### Custom Dendritic Nix Classes

[Custom classes](https://den.oeiuwq.com/guides/custom-classes) is how Den implements `homeManager`, `hjem`, `wsl`, `microvm` support. You can use the very same mechanism to create your own classes.

```nix
# Example: A class for role-based configuration between users and hosts

roleClass =
  { host, user }:
  { class, aspect-chain }:
  den._.forward {
    each = lib.intersectLists (host.roles or []) (user.roles or []);
    fromClass = lib.id;
    intoClass = _: host.class;
    intoPath = _: [ ];
    fromAspect = _: lib.head aspect-chain;
  };

den.ctx.user.includes = [ roleClass ];

den.hosts.x86_64-linux.igloo = {
  roles = [ "devops" "gaming" ];
  users = {
    alice.roles = [ "gaming" ];
    bob.roles = [ "devops" ];
  };
};

den.aspects.alice = {
  # enabled when both support gaming role
  gaming = { pkgs, ... }: { programs.steam.enable = true; };
};

den.aspects.bob = {
  # enabled when both support devops role
  devops = { pkgs, ... }: { virtualisation.podman.enable = true; };

  # not enabled at igloo host (bob missing gaming role on that host)
  gaming = {};
};
```

### Guarded Forwarding Classes

Forward guards allow feature-detection without mkIf/mkMerge cluttering.

Aspects can simply assign configurations into a class (here `persys`)
from any file, without any `mkIf`/`mkMerge` cluttering. The logic for
determining if the class takes effect is defined at a single place.

> Example inspired by @Doc-Steve

```nix
# Aspects use the `persys` class without any conditional. And guard guarantees
# settings are applied **only** when impermanence module has been imported.
persys = { host }: den._.forward {
  each = lib.singleton true;
  fromClass = _: "persys";
  intoClass = _: host.class;
  intoPath = _: [ "environment" "persistance" "/nix/persist/system" ];
  fromAspect = _: den.aspects.${host.aspect};
  guard = { options, config, ... }: options ? environment.persistance;
};

# enable on all hosts
den.ctx.host.includes = [ persys ];

# aspects just attach config to custom class
den.aspects.my-laptop.persys.hideMounts = true;
```

### User-defined Extensions to Den Framework.

See example [`template/microvm`](https://den.oeiuwq.com/tutorials/microvm) for an example
of custom `den.ctx` and `den.schema` extensions for supporting
Declarative [MicroVM](https://microvm-nix.github.io/microvm.nix/declarative.html) guests with automatic host-shared `/nix/store`.

```nix
den.hosts.x86_64-linux.guest = {};
den.hosts.x86_64-linux.host = {
  microvm.guests = [ den.hosts.x86_64-linux.guest ];
};

den.aspects.guest = {
  # propagated into host.nixos.microvm.vms.<name>;
  microvm.autostart = true;

  # guest supports all Den features.
  includes = [ den.provides.hostname ];
  # As MicroVM guest propagated into host.nixos.microvm.vms.<name>.config;
  nixos = { pkgs, ... }: { environment.systemPackages = [ pkgs.hello ]; };
};
```
