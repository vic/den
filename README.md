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

# den - Context-aware Dendritic Nix configurations.

> den and [vic](https://bsky.app/profile/oeiuwq.bsky.social)'s [dendritic libs](https://dendritic.oeiuwq.com) made for you with Love++ and AI--. If you like my work, consider [sponsoring](https://dendritic.oeiuwq.com/sponsor)

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


</div>
</td>
<td>


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

</td>


</tr>
</table>



## Code example (OS configuration domain)

```nix
# Define hosts, users & homes
den.hosts.x86_64-linux.lap.users.vic = {};
den.hosts.aarch64-darwin.mac.users.vic = {};
den.homes.aarch64-darwin.vic = {};
```

```console
$ nixos-rebuild switch --flake .#lap
$ darwin-rebuild switch --flake .#mac
$ home-manager   switch --flake .#vic
```

```nix
# extensible base modules for common, typed schemas
den.base.user = { user, lib, ... }: {
  config.classes =
    if user.userName == "vic" then [ "hjem" "maid" ]
    else lib.mkDefault [ "homeManager" ];

  options.mainGroup = lib.mkOption { default = user.userName; };
};
```

```nix
# modules/my-laptop.nix
{ den, inputs, ... }: {
  den.aspects.my-laptop = {
    # re-usable configuration aspects
    includes = [ den.aspects.work-vpn ];

    # regular nixos/darwin modules or any other Nix class
    nixos  = { pkgs, ... }: { imports = [ inputs.disko.nixosModules.disko ]; };
    darwin = { pkgs, ... }: { environment.packages = [ pkgs.hello ]; };

    # host can contribute to its users' environment
    homeManager.programs.vim.enable = true;
  };
}
```

```nix
# modules/vic.nix
{ den, ... }: {
  den.aspects.vic = {
    # supports multiple home environments
    homeManager = { pkgs, ... }: { };
    hjem.files.".envrc".text = "use flake ~/hk/home";
    maid.kconfig.settings.kwinrc.Desktops.Number = 3;

    # user can contribute configurations to all hosts it lives on
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

```nix
# custom user-defined Nix classes.

# any aspect can use my `persys` class to forward configs into
#   nixos.environment.persistance."/nix/persist/system"
# **ONLY** when environment.persistance option is present at host.
persys = { host }: den._.forward {
  each = lib.singleton true;
  fromClass = _: "persys";
  intoClass = _: host.class;
  intoPath = _: [ "environment" "persistance" "/nix/persist/system" ];
  fromAspect = _: den.aspects.${host.aspect};
  guard = { options, ... }: options ? environment.persistance;
};

# enable on all hosts
den.ctx.host.includes = [ persys ];

# becomes nixos.environment.persistance."/nix/persist/system".hideMounts = true;
# no mkIf, set configs and guard ensures to include only when Impermanence exists
den.aspects.my-laptop.persys.hideMounts = true;
```
