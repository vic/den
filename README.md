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

- focused on configurations [definition](#core-concepts).
- incremental [dependencies](#user-influencing-the-host).
- multi-platform, multi-tenant hosts.
- shareable HM in OS and standalone.
- `nixos`/`darwin`/`systemManager`/any Nix `class`.
- stable/unstable input [channels](#custom-configuration-factories).
- customizable config factories and output attrs.
- [batteries](#batteries-included-common-aspects-ready-to-use) included and replaceable.
- features [tested](templates/default/modules/_example/ci.nix) with [examples](templates/default/modules/).

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

Need more batteries? See [vic/denful](https://github.com/vic/denful)

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

Our [default](templates/default/modules/_profile/) template provides a quick-start layout.

</td>
</tr>
</table>

## Aspect-Oriented Dendritic Nix

`den` promotes aspect-oriented design in Nix configurations. This approach encourages separation of concerns and modularity.

- **Declarative & Composable**: Define system behaviors as independent aspects and compose them as needed.
- **Batteries Included**: A collection of ready-to-use aspects for common configuration tasks are provided. They are opt-in and replaceable.
- **Multi-Platform**: Manages configurations for NixOS, macOS (via `nix-darwin`), and user environments (via `home-manager`). It is extensible to any Nix-based configuration class.
- **Parametric Configuration**: Aspects can be functions that receive context, allowing for configurations that adapt to their environment. This facilitates bidirectional configuration, where users can influence their host system and vice-versa.
- **Modular**: The use of freeform attributes for hosts, users, and homes allows for passing custom metadata across any Nix configuration class, communicating values across nixos, home-manager or any other class not only in the same file but anywhere in the system.

## Core Concepts

`den` separates the *what* (the systems and users) from the *how* (the configuration details), enabling a modular and reusable setup.

### Hosts, Users, and Standalone Homes

At the core of `den` is a clear separation of systems and their features definition. You declare your hosts, the users on those hosts, and any standalone `home-manager` configurations in a straightforward manner. This declaration is pure data, free of configuration concerns.

```nix
# Declare your hosts and their users
den.hosts.x86_64-linux.my-server.users.web = {};
den.hosts.aarch64-darwin.my-laptop.users.vic = {};

# Declare standalone home-manager configurations
den.homes.aarch64-darwin.dan = {
  role = "designer"; # Custom metadata accessible anywhere
};
```

This structure allows you to manage heterogeneous environments with clarity. The actual configuration is applied using standard tools like `nixos-rebuild`, `darwin-rebuild`, or `home-manager`. For the schema, see the [type definitions](modules/_types.nix).

### Aspects: Composable Configuration Units

Aspects are the building blocks of your system's configuration, powered by the [`flake-aspects`](https://github.com/vic/flake-aspects) library. Aspects are self-contained collections of modules that define a specific feature, they can be organized in a tree-like structure (via its `provides` attribute) and declare dependencies upon each other (via its `includes` attribute).

`den` automatically creates aspects for each host, user, and home. It also wires the basic configuration dependencies between them. So you can then attach features to them.

```nix
den.aspects.my-server = {
  nixos.services.nginx.enable = true;
  includes = [ den.aspects.security den.aspects.monitoring ];
};
```

This promotes a clean separation of concerns. Dependencies between aspects are declared in [dependencies.nix](modules/aspects/dependencies.nix).

### Default Aspects

You can define default aspects that apply to all hosts, users, or standalone homes. This is useful for establishing a baseline configuration across your entire infrastructure.

```nix
# Static. Apply a baseline security aspect to all hosts
den.default.host.includes = [ den.aspects.baseline-security ];

# Parametric. Automatically configures at OS and home level
den.default.user._.user.includes = [ den._.define-user ];
```

These defaults act as a foundation upon which more specific configurations can be built.

### Parametric Aspects & Bidirectional Configuration

Parametric aspects are functions that receive context (like `host`, `user` or `home`) and return an aspect. This allows for dynamic, context-aware configuration. This enables a pattern of **bidirectional configuration**, where hosts and users can influence each other's settings.

#### User influencing the Host

A user's aspect can contribute configuration to the host they reside on, conditional on the host's properties.

```nix
# Contributes configuration only on WSL hosts
den.aspects.alice._.user.includes = [
  ({ host, user }:
    if host ? wsl
    then { nixos.wsl.defaultUser = user.userName; }
    else { })
];
```

#### Host influencing its Users

Conversely, a host can provide a common environment or set of tools to all its users.

```nix
# A host aspect that provides a common environment to all its users
den.aspects.devserver._.common-user-env = { host, user }: {
  homeManager.programs.vim.enable = true;
};
```

This bidirectional capability allows for creating reusable and adaptable configurations that respect the boundaries between different system components.

### Batteries Included: Common Aspects Ready to Use

`den` comes with a set of pre-defined, replaceable aspects for common configuration tasks. These aspects are opt-in and replaceable, they also serve as examples for you to create your own.

- [`home-manager`](modules/aspects/provides/home-manager.nix): Integrates `home-manager` configurations into your hosts.
- [`unfree`](modules/aspects/provides/unfree.nix): Enables the use of unfree packages.
- [`import-tree`](modules/aspects/provides/import-tree.nix): Provides a migration path for non-dendritic configurations.
- [`primary-user`](modules/aspects/provides/primary-user.nix): Grants administrative privileges to a user.
- [`define-user`](modules/aspects/provides/define-user.nix): Manages user account creation across different operating systems.
- [`user-shell`](modules/aspects/provides/user-shell.nix): Sets the default shell for a user.

You can find the implementation of these in the [provides directory](modules/aspects/provides/).

### Custom Configuration Factories

`den` allows you to specify custom builders for your configurations. This is useful for integrating new Nix configuration classes or for using different input channels (e.g., stable vs. unstable) on different parts of your system.

For example, you can use a specific factory for a WSL host:

```nix
den.hosts.x86_64-linux.wsl.instantiate = inputs.nixpkgs-stable.lib.nixosSystem;
```

This gives fine-grained control over how your systems are built.

## 🧪 Testing & Examples

The CI tests for `den` serve as a comprehensive set of usage examples. You can find them in the [`_example` directory](templates/default/modules/_example). These demonstrate patterns and showcase `den`'s capabilities.

For further inspiration, you can explore configurations using `den` on GitHub, such as [`vic/vix`](https://github.com/vic/vix/tree/den), or by [searching for repos](https://github.com/search?q=vic%2Fden+language%3ANix&type=code).

Join the [discussion](https://github.com/vic/discussions). Ask questions, feedback or share how you are using den to inspire others.
