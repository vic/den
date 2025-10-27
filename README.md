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

- focused on host/home definitions.
- host/home configs via aspects.
- multi-platform, multi-tenant hosts.
- shareable-hm in os and standalone.
- extensible for new host/home classes.
- stable/unstable input channels.
- customizable os/home factories.

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

  # That's it! The rest is adding flake.aspects.
}
```

🧩 [Aspect-oriented](https://github.com/vic/flake-aspects) dendritic modules ([example](templates/default/modules/_example/aspects.nix))

```nix
# modules/work-laptop.nix
{
  flake.aspects.work-laptop = {
    darwin = ...; # (see nix-darwin options)
    nixos  = ...; # (see nixos options)
    includes = with flake.aspects; [ vpn office ];
  };
}

# modules/vic.nix
{
  flake.aspects.vic = {
    homeManager = ...;
    nixos = ...;
    includes = with flake.aspects; [ tiling-wm ];
    provides.work-laptop = { host, user }: {
      darwin.system.primaryUser = user.userName;
      nixos.users.users.vic.isNormalUser = true;
    };
  };
}
```

</td>
</tr>
</table>

## Core Concepts

`den` separates the definition of systems from their configuration. You declare your machines and users using a concise syntax, and then attach features to them using an aspect-oriented approach.

- **Hosts & Homes**: You define *what* systems exist (e.g., `den.hosts.my-laptop` or `den.homes.my-user`). This part is focused only on the system's identity and its users.

- **Aspects**: You define *how* systems are configured using `flake.aspects`. An aspect is a collection of configuration settings. For example, a `work` aspect might add VPN software, while a `gaming` aspect might add Steam. Aspects are applied to hosts and homes to build the final system configuration.

This separation keeps your system definitions clean and makes your configurations reusable and composable.

## Basic Usage

The syntax for defining hosts and standalone homes is minimal and focuses on the system's identity, not its features.

### Defining a Host

To define a NixOS or Nix-Darwin host, add an entry to `den.hosts`. The system type (`x86_64-linux`, `aarch64-darwin`, etc.) determines the host's architecture and operating system class (`nixos` or `darwin`).

```nix
# modules/hosts.nix -- see <den>/nix/types.nix for schema
{
  # This one-liner defines a host named 'work-laptop' with a single user 'vic'.
  den.hosts.x86-64-linux.work-laptop.users.vic = {};
}
```

`den` uses this definition to generate a `flake.nixosConfigurations.work-laptop` output, which you can build and activate using:

```console
nixos-rebuild switch --flake .#work-laptop
```

### Defining a Standalone Home

For home-manager configurations that are not tied to a specific host (e.g., for use on non-NixOS systems), use `den.homes`.

```nix
# modules/homes.nix -- see <den>/nix/types.nix for schema
{
  # Defines a standalone home-manager configuration for the user 'vic'.
  den.homes.aarch64-darwin.vic = {};
}
```

This generates a `flake.homeConfigurations.vic` output, which can be activated with:

```console
home-manager switch --flake .#vic
```

## Configuring with Aspects

Once you have defined a host or home, you use aspects to configure it. By default, a host named `work-laptop` is associated with the `work-laptop` aspect, and a user named `vic` is associated with the `vic` aspect.

You can contribute to these aspects from any module. Dendritic aspects are incremental, meaning many files can add settings to the same aspect.

```nix
# modules/aspects.nix
{
  # Add configuration to the 'work-laptop' aspect.
  flake.aspects.work-laptop = {
    nixos = { ... }; # NixOS-specific settings
  };

  # Add configuration to the 'vic' aspect.
  flake.aspects.vic = {
    homeManager = { ... }; # home-manager settings
  };
}
```

### Default Aspects

This library also provides `default` aspects to apply global configurations to all hosts, users, or homes of a certain class.

- `flake.aspects.default.host`: Applied to all hosts.
- `flake.aspects.default.user`: Applied to all users within hosts.
- `flake.aspects.default.home`: Applied to all standalone homes.

## Advanced Customization

### Aspect Composition

Aspects can be composed together to create complex configurations from smaller, reusable parts.

- **`includes`**: An aspect can include other aspects. For example, a `laptop` aspect could include `wifi` and `power-saving` aspects.
- **`provides`**: An aspect can provide configuration to another. For example, a user aspect can provide user-specific settings to the host it's running on.

The `flake.aspects` system resolves this dependency graph to build the final configuration module. For a deeper dive, refer to the [`flake-aspects`](https://github.com/vic/flake-aspects) documentation.

### Freeform Attributes

The `host`, `user`, and `home` types support freeform attributes, allowing you to pass custom metadata to your aspects.

```nix
# modules/hosts.nix
{
  den.hosts.x86-64-linux.work-laptop = {
    # Custom attribute
    isWorkMachine = true;
    users.vic = {};
  };
}
```

This metadata is accessible within aspect functions, enabling you to create more dynamic and context-aware configurations.

### Custom Factories (`instantiate`)

For ultimate control, each `host` and `home` definition accepts an optional `instantiate` function. This allows you to override the default NixOS or home-manager builders, for example, to support a new OS type or to pass `extraSpecialArgs`.

**Example: Using a specific `nixpkgs` input for a host:**

```nix
# modules/wsl-instantiate.nix
{ inputs, ... }:
{
  flake.inputs.nixpkgs-stable.url = "https://channels.nixos.org/nixos-25.05/nixexprs.tar.xz";
  flake.inputs.nixos-wsl.inputs.nixpkgs.follows = "nixpkgs-stable";

  den.hosts.x86_64-linux.my-wsl = {
    # Override the default builder to use the stable nixpkgs input.
    # See <den>/nix/config.nix: `osConfiguration`
    instantiate = inputs.nixpkgs-stable.lib.nixosSystem;
  };
}
```

**Example: Using `extraSpecialArgs` in a standalone home:**

While using `specialArgs` is often an anti-pattern in Dendritic Nix (as inputs are already available to all modules), the `instantiate` function provides an escape hatch if you have no other choice.

```nix
{ inputs, self, ... }:
{
  den.homes.x86_64-linux."vic@work-laptop" = {
    aspect = "vic"; # Re-use the same 'vic' aspect
    # See <den>/nix/config.nix: `homeConfiguration`
    instantiate = { pkgs, modules }: inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs modules;
      # Caution: Use specialArgs sparingly.
      extraSpecialArgs.os-config = self.nixosConfigurations.work-laptop.config;
    };
  };
}
```

### Advanced Aspect Patterns

The `_example/aspects.nix` file demonstrates several powerful patterns for creating flexible and maintainable configurations.

#### Global User-to-Host Configuration (`provides.hostUser`)

A user aspect can provide configuration to *any* host it is a part of using `provides.hostUser`. This is useful for defining settings that should apply whenever a user is present on a system, regardless of the specific host.

For example, to make the user `alice` an administrator on any NixOS host she belongs to:

```nix
# modules/aspects.nix
{
  flake.aspects.alice.provides.hostUser = { user, host }: {
    # These settings are applied to any host that includes the user 'alice'.
    nixos.users.users.${user.userName} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
}
```

#### Parametric and Class-Based Defaults

You can define default settings that apply to all hosts, users, or homes. This is a powerful way to enforce global standards and reduce duplication.

##### Class-Based Defaults

You can apply settings to all systems of a specific *class* (e.g., `nixos`, `darwin`, `homeManager`) by adding them directly to the default aspect.

```nix
# modules/aspects.nix
{
  # Set stateVersion for all NixOS hosts
  flake.aspects.default.host.nixos.system.stateVersion = "25.11";

  # Set stateVersion for all Darwin hosts
  flake.aspects.default.host.darwin.system.stateVersion = 6;

  # Set stateVersion for all standalone home-manager homes
  flake.aspects.default.home.homeManager.home.stateVersion = "25.11";
}
```

##### Parametric Defaults (`includes`)

For more dynamic configurations, you can add *functions* to the `includes` list of a default aspect. These functions are called for every host, user, or home, and receive the corresponding object (`host`, `user`, or `home`) as an argument. This allows you to generate configuration that is parameterized by the system's properties.

For instance, to set the `hostName` for every host automatically based on its definition:

```nix
# modules/aspects.nix
{
  # 1. Define a parametric aspect (a function) that takes a host and returns
  #    a configuration snippet.
  flake.aspects.example.provides.hostName = { host }: { class, ... }: {
    ${class}.networking.hostName = host.hostName;
  };

  # 2. Include this function in the default host includes.
  #    This function will now be called for every host defined in `den.hosts`.
  flake.aspects.default.host.includes = [
    flake.aspects.example.provides.hostName
  ];
}
```

###### How Parametric Defaults Work

Under the hood, `aspects.default.host`, `aspects.default.user`, and `aspects.default.home` are not static aspects but **functors**. When `den` evaluates a system, it invokes the corresponding default functor, which in turn iterates over the functions in its `includes` list. It calls each function with a context-specific object and merges the resulting configuration snippets.

The parameters passed to the functions in each `includes` list are as follows:

- `flake.aspects.default.host.includes`: Each function receives the `host` object (`{ host }`).
- `flake.aspects.default.user.includes`: Each function receives the `host` and `user` objects (`{ host, user }`). This applies to users defined within a host.
- `flake.aspects.default.home.includes`: Each function receives the `home` object (`{ home }`). This applies to standalone home-manager configurations.

This mechanism allows you to create highly reusable and context-aware default configurations that adapt to each system's specific attributes.

#### Conditional Logic in Aspects

Aspect provider functions can contain conditional logic to apply different configurations based on the properties of the host or user. This is useful for handling exceptions and special cases without creating dozens of tiny aspects.

```nix
# modules/aspects.nix
{
  flake.aspects.example.provides.user = { user, host }:
    let
      # Default configuration for a user
      defaultConfig = {
        nixos.users.users.${user.userName}.isNormalUser = true;
        darwin.system.primaryUser = user.userName;
      };

      # Special configuration for NixOS-on-WSL 
      hostSpecificConfig.adelie = {
        nixos.defaultUser = user.userName;
      };
    in
    # Use the host-specific config if it exists, otherwise use the default.
    hostSpecificConfig.${host.name} or defaultConfig;
}
```

### Provider Precedence

When a user aspect provides configuration to a host, `den` follows a specific order of precedence. This allows you to define a general configuration and override it for specific hosts.

The precedence is as follows:

1. **Host-Specific Provider (`<user_aspect>.provides.<host_aspect>`)**: `den` first looks for a provider in the user's aspect that is named after the host's aspect. This is the most specific and will be used if it exists.

   ```nix
   # User 'vic' provides specific settings only for the 'work-laptop' host.
   flake.aspects.vic.provides.work-laptop = { host, user }: {
     nixos.services.openssh.enable = true;
   };
   ```

1. **Generic Host Provider (`<user_aspect>.provides.hostUser`)**: If a host-specific provider is not found, `den` falls back to the generic `provides.hostUser` provider. This is the same provider discussed in the "Advanced Aspect Patterns" section.

   ```nix
   # User 'vic' provides these settings to any host that doesn't have a more
   # specific provider.
   flake.aspects.vic.provides.hostUser = { user, ... }: {
     nixos.users.users.${user.userName}.extraGroups = [ "wheel" ];
   };
   ```

1. **No Provider**: If neither a specific nor a generic provider is found, no configuration is provided by the user aspect to the host.

This mechanism allows you to define a default set of user-to-host configurations and then create exceptions for specific machines, leading to a more flexible and maintainable setup.
