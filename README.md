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

- focused on configurations [definition](#hostsusers--standalone-homes).
- incremental [dependencies](#aspects).
- multi-platform, multi-tenant hosts.
- shareable HM in OS and standalone.
- `nixos`/`darwin`/`systemManager`/any Nix `class`.
- stable/unstable input [channels](#custom-configuration-factories).
- customizable config factories and output attrs.
- [batteries](#batteries-included) included and replaceable.
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

## Dendritic Nix - powered by den.

`den` allows Dendritic Nix implementations with aspect-oriented design:

- **🎯 Declarative & Composable**: Define systems once, reuse their behaviour everywhere.
- **🔧 Batteries Included**: Ready-to-use aspects for common tasks. Opt-in and fully replaceable.
- **🌍 Multi-Platform**: NixOS, Darwin, Home Manager, System Manager, any other Nix configuration class. Supports multiple input channels, configuration factories and output attributes.
- **⚡ Parametric Power**: Context-aware configurations. Users can contribute configuration to their hosts. Hosts can provide configuration to their user's homes.
- **🧩 Modular**: Mix and match features effortlessly, you are just applying functions. Host/Users/Homes are freeforms allowing custom metadata to be passed across any Nix configuration class.

## 📖 Core Concepts

### Hosts+Users & Standalone-Homes

Simply declare what systems exist and their users. No config details here!

```nix
den.hosts.x86_64-linux.my-server.users.web = {};
den.hosts.aarch64-darwin.my-laptop.users.vic = {};

den.homes.aarch64-darwin.dan = {
  role = "designer"; # your custom metadata across Nix classes
};
```

See schema: [\_types.nix](modules/_types.nix)

Use standard tools like `nixos-rebuild`, `darwin-rebuild` or `home-manager` to apply your configurations.

### Aspects

Attach features using composable aspects powered by the [`flake-aspects`](https://github.com/vic/flake-aspects) lib.

Aspects can be nested or organization and include others as dependencies, forming configuration graphs.

```nix
den.aspects.my-server = {
  nixos.services.nginx.enable = true;
  includes = [ den.aspects.security den.aspects.monitoring ];
};
```

Den creates aspects for each host/user and home. Dependencies resolved via [dependencies.nix](modules/aspects/dependencies.nix)

### Parametric Aspects

Functions receiving context and producing aspects for conditional configuration:

```nix
# modules/aspects.nix
{
  den.aspects.alice._.user.includes = [
    # Provide tmux config to the host if the user is 'alice' on a non-darwin system
    ({ host, user }:
      if host.class != "darwin"
      then { nixos.programs.tmux.enable = true; }
      else { })
  ];
}
```

See: [\_example/aspects.nix](templates/default/modules/_example/aspects.nix)

## Batteries Included

- `den._.define-user`: User accounts across OS/home
- `den._.home-manager`: Integrate home-manager into hosts
- `den._.primary-user`: Admin privileges
- `den._.user-shell`: Set user default shell
- `den._.unfree`: Allow unfree packages in any Nix class
- `den._.import-tree`: Import non-dendritic trees for easy migration path.

See: [provides/](modules/aspects/provides/)

## Custom Configuration Factories

Override builders for different input channels or custom Nix configuration classes:

```nix
den.hosts.x86_64-linux.wsl.instantiate = inputs.nixpkgs-stable.lib.nixosSystem;
```

## Reusable Configuration Aspects.

Write modular, generic configurations that are focused on features, not on the specific places are applied.

See: [batteries](modules/aspects/provides) & [profiles](templates/default/modules/_profile)

## 🧪 Testing & Examples

Our CI tests double as comprehensive examples. See [`_example/`](templates/default/modules/_example) for real-world patterns.

For inspiration, check [`vic/vix`](https://github.com/vic/vix/tree/den) or search [GitHub for den](https://github.com/search?q=vic%2Fden+language%3ANix&type=code).
