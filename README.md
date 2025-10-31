<p align="right">
  <a href="https://vic.github.io/dendrix/Dendritic.html"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
</p>

# den - Dendritic Nix Host Configurations

<table>
<tr>
<td>

<img width="400" height="400" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" />

- focused on host/home [definitions](#basic-usage).
- incremental [dependencies](modules/aspects/dependencies.nix).
- multi-platform, multi-tenant hosts.
- shareable-hm in os and standalone.
- adaptable to new host/home classes.
- stable/unstable input [channels](#custom-factories-instantiate).
- customizable os/home factories.
- [batteries](#batteries-included) included and replaceable.
- features [tested](templates/default/modules/_example/ci.nix) with [examples](templates/default/modules/_example).

**❄️ Try it now! Launch our template VM:**

```console
nix run github:vic/den
```

Or clone it and run the VM as you edit

```console
nix flake init -t github:vic/den
nix flake update den
nix run .#vm
```

Need more batteries? see [vic/denful](https://github.com/vic/denful)

</td>
<td>

<em><h4>A refined, minimalistic approach to declaring<br/>Dendritic Nix host configurations.</h4></em>

🏠 Concise [hosts+users](templates/default/modules/_example/hosts.nix) and [standalone-homes](templates/default/modules/_example/homes.nix) definition.

```nix
# modules/den.nix -- reuse home in nixos & standalone.
{
  # $ nixos-rebuild switch --flake .#work-laptop
  den.hosts.x86-64-linux.work-laptop.users.vic = {};
  # $ home-manager switch --flake .#vic
  den.homes.aarch64-darwin.vic = { };

  # That's it! The rest is adding den.aspects.
}
```

🧩 [Aspect-oriented](https://github.com/vic/flake-aspects) dendritic modules ([example](templates/default/modules/_example/aspects.nix))

```nix
# modules/work-laptop.nix
{ den, ... }:
{
  den.aspects.work-laptop = {
    darwin = ...; # (see nix-darwin options)
    nixos  = ...; # (see nixos options)
    includes = with den.aspects; [ vpn office ];
  };
}

# modules/vic.nix
{ den, ... }:
{
  den.aspects.vic = {
    homeManager = ...;
    nixos = ...;
    includes = with den.aspects; [ tiling-wm ];
    provides.work-laptop = { host, user }: {
      darwin.system.primaryUser = user.userName;
      nixos.users.users.vic.isNormalUser = true;
    };
  };
}
```

For real-world examples, see [`vic/vix`](https://github.com/vic/vix/tree/den)
or this [search](https://github.com/search?q=vic%2Fden+language%3ANix&type=code).

</td>
</tr>
</table>

## Core Concepts

`den` separates the definition of systems from their configuration. You declare your machines and users using a concise syntax, and then attach features to them using an aspect-oriented approach.

- **Hosts & Homes**: You define *what* systems exist (e.g., `den.hosts.my-laptop` or `den.homes.my-user`). This part is focused only on the system's identity and its users. See the schema in [`modules/_types.nix`](modules/_types.nix).

- **Aspects**: You define *how* systems are configured using `den.aspects`. An [aspect](https://github.com/vic/flake-aspects) is a tree of configuration modules. Aspects can provide modules to other aspects forming a graph of configurations. Aspect dependency graphs are applied to hosts and homes to build the final system configuration.

This separation keeps your system definitions clean and makes your configurations reusable and composable.

## Usage

The syntax for defining hosts and standalone homes is minimal, focusing on identity, not features. All available options are defined in the [`modules/_types.nix`](modules/_types.nix) schema.

### Defining Hosts and Homes

Define NixOS/Nix-Darwin hosts in `den.hosts` and standalone `home-manager` configurations in `den.homes`.

```nix
# modules/systems.nix
{
  # Defines host 'rockhopper' with user 'alice'.
  # Builds with: $ nixos-rebuild switch --flake .#rockhopper
  den.hosts.x86_64-linux.rockhopper.users.alice = { };

  # Defines standalone home 'cam'.
  # Builds with: $ home-manager switch --flake .#cam
  den.homes.x86_64-linux.cam = { };
}
```

*For a working example, see [`templates/default/modules/_example/hosts.nix`](templates/default/modules/_example/hosts.nix) and [`homes.nix`](templates/default/modules/_example/homes.nix).*

### Configuring with Aspects

`den` automatically creates an aspect for each host and user. A host `rockhopper` gets a `den.aspects.rockhopper` aspect, and a user `alice` gets `den.aspects.alice`. You can add configuration to these aspects from any module.

```nix
# modules/features.nix
{
  # Add configuration to the 'rockhopper' aspect
  den.aspects.rockhopper.nixos.networking.hostName = "rockhopper";

  # Add configuration to the 'alice' aspect
  den.aspects.alice.homeManager.programs.helix.enable = true;
}
```

Dependencies between host/user aspects is defined by [`modules/aspects/dependencies.nix`](modules/aspects/dependencies.nix). For a full example, see [`templates/default/modules/_example/aspects.nix`](templates/default/modules/_example/aspects.nix).

### Default Configurations

Apply global settings using `default` aspects, defined in [`modules/aspects/defaults.nix`](modules/aspects/defaults.nix).

- `den.default.host`: Applied to all hosts.
- `den.default.user`: Applied to all users within hosts.
- `den.default.home`: Applied to all standalone homes.

You can set static values per class or use parametric includes for dynamic, context-aware configurations.

```nix
# modules/defaults.nix
{
  # Static default: set state version for all NixOS hosts
  den.default.host.nixos.system.stateVersion = "25.05";

  # Parametric default: define a user account on every host
  den.default.user._.user.includes = [
    ({ user, host }: {
      ${host.class}.users.users.${user.name}.isNormalUser = true;
    })
  ];
}
```

*See this in action in [`templates/default/modules/_example/defaults.nix`](templates/default/modules/_example/defaults.nix) and [`aspects.nix`](templates/default/modules/_example/aspects.nix).*

## Batteries Included

`den` provides ready-to-use aspects for common patterns.

- **`den.home-manager`**: Integrates `home-manager` into NixOS/Darwin hosts. See [`modules/aspects/batteries/home-manager.nix`](modules/aspects/batteries/home-manager.nix).
- **`den.import-tree`**: Recursively imports non-dendritic `.nix` files, ideal for migrating existing setups. See [`modules/aspects/batteries/import-tree.nix`](modules/aspects/batteries/import-tree.nix).

Enable them by adding them to an aspect's `includes` list, for example, to enable `home-manager` for all hosts:

```nix
# modules/home-managed.nix
{ den, ... }:
{
  den.default.host._.host.includes = [ den.home-manager ];
}
```

## Advanced Customization

### Aspect Composition

Aspects can include other aspects (`includes`) or provide configuration to them (`provides`), creating a powerful dependency graph. A user aspect, for example, can provide host-level settings to the host it's running on.

```nix
# modules/aspects.nix
{
  den.aspects.alice._.user.includes = [
    ({ host, user }:
      # Provide tmux config to the host if the user is 'alice' on a non-darwin system
      if user.userName == "alice" && host.class != "darwin"
      then { nixos.programs.tmux.enable = true; }
      else { })
  ];
}
```

*For more patterns, see [`flake-aspects`](https://github.com/vic/flake-aspects) and the examples in [`templates/default/modules/_example/aspects.nix`](templates/default/modules/_example/aspects.nix).*

### Custom Factories (`instantiate`)

You can override the default system builders (`nixosSystem`, `homeManagerConfiguration`) by providing a custom `instantiate` function. This is useful for supporting new system types or using different `nixpkgs` channels.

```nix
# modules/wsl.nix
{ inputs, ... }:
{
  den.hosts.x86_64-linux.my-wsl = {
    # Use a different builder for this host
    instantiate = inputs.nixpkgs-stable.lib.nixosSystem;
  };
}
```

## Testing

The template includes a comprehensive set of CI checks in [`templates/default/modules/_example/ci.nix`](templates/default/modules/_example/ci.nix). These checks serve as live documentation, demonstrating and verifying all core features and aspect patterns. Refer to this file for concrete usage examples.
