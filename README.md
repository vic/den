<p align="right">
  <a href="https://github.com/sponsors/vic"><img src="https://img.shields.io/badge/sponsor-vic-white?logo=githubsponsors&logoColor=white&labelColor=%23FF0000" alt="Sponsor Vic"/>
  </a>
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

- Dendritic: same concern, different classes and context-aware.

- Small, [DRY](modules/aspects/provides/unfree.nix) & [`class`-generic](modules/aspects/provides/primary-user.nix) modules.

- [Parametric](modules/aspects/provides/define-user.nix) over `host`/`home`/`user`.

- [Share](templates/default/modules/_profile/namespace.nix) aspects across systems & repos.

- Bidirectional [dependencies](modules/aspects/dependencies.nix): user/host contributions.

- Custom factories for any Nix `class`.

- Use `stable`/`unstable` channels per config.

- Freeform `host`/`user`/`home` [schemas](modules/_types.nix) (no `specialArgs`).

- Multi-platform, multi-tenant hosts.

- [Batteries](modules/aspects/provides/): Opt-in, replaceable aspects.

- [Well-tested](templates/default/modules/_example/ci.nix) with an [example suite](templates/default/modules/).

Need more batteries? See [vic/denful](https://github.com/vic/denful).

Join our [community discussion](https://github.com/vic/den/discussions).

</div>
</td>
<td>

🏠 Define [Hosts, Users](templates/default/modules/_example/hosts.nix) & [Homes](templates/default/modules/_example/homes.nix) concisely.

See schema in [`_types.nix`](modules/_types.nix).

```nix
# modules/hosts.nix
# OS & standalone homes share 'vic' aspect.
# $ nixos-rebuild switch --flake .#my-laptop
# $ home-manager switch --flake .#vic
{
  den.hosts.x86-64-linux.laptop.users.vic = {};
  den.homes.aarch64-darwin.vic = {};
}
```

🧩 [Aspect-oriented](https://github.com/vic/flake-aspects) incremental features. ([example](templates/default/modules/_example/aspects.nix))

Any module can contribute configurations to aspects.

```nix
# modules/my-laptop.nix
{ den, ... }: {
  den.aspects.my-laptop = {
    includes = [
      den.aspects.vpn # { host } => config
      den._.home-manager # battery
    ];
    nixos  = { /* NixOS options */ };
    darwin = { /* nix-darwin options */ };
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
    }
    includes = [ 
      den.aspects.tiling-wm 
      den._.primary-user 
    ];
  };
}
```

For real-world examples, see [`vic/vix`](https://github.com/vic/vix/tree/den) or this [GH search](https://github.com/search?q=vic%2Fden+language%3ANix&type=code).

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

Our [default template](templates/default) provides a [profile-based layout](templates/default/modules/_profile/) for a quick start.

</td>
</tr>
</table>

You are done! You know everything to start creating configurations with `den`.

Feel free to to __explore__ the codebase, particularly our [included batteries](modules/aspects/provides) and [tests](templates/default/modules/_example).

# Learn More

If you want to learn how `den` works, the following sections detail its concepts and patterns.

<details>
<summary>

### Basic Concepts

> Learn about static vs. parametric aspects, the default aspect, and dependencies.

</summary>

`den` has two fundamental types of aspects: _static_ and _parametric_.

<table>
<tr>
<td>

#### **Static** aspects are attribute sets.

An aspect is a set of modules for different `classes`, configuring a single concern across them.

```nix
den.aspects.my-laptop = {
  nixos  = { /* ... */ };
  darwin = { /* ... */ };

  # Nested aspects via `_`
  # (alias for `provides`)
  _.gaming = {
    nixos = { /* ... */ };
    # Dependency graph via `includes`
    includes = [ den.aspects.nvidia-gpu ];
  };
};
```

</td>
<td>

#### **Parametric** aspects are functions.

They take a `context` and return a configuration.

```nix
# A `{ host, gaming }` contextual aspect.
hostFunction = { host, gaming }: {
  nixos.networking.hostName = host.hostName;
};

# A parametric aspect can request context-aware
# configurations from other aspects.
hostParametric = { host }: {
  __functor = den.lib.parametric {
    inherit host;
    gaming.emulators = [ "nes" ];
  };
  includes = [ hostFunction den.default ];
}
```

</td>
</tr>
</table>

`den` uses several default contexts to manage [dependencies](modules/aspects/dependencies.nix):

- `{ host }`, `{ user, host }`, `{ home }`
- `{ fromUser, toHost }`, `{ fromHost, toUser }`

</td>
</tr>
</table>

### The Default Aspect and Dependencies

`den` features a special aspect, `den.default`, which applies global configurations. It is automatically included in all hosts, users, and homes, receiving the appropriate context (e.g., `den.default { inherit home; }`).

You can register static values or context-aware parametric aspects within `den.default`. This allows you to define defaults that apply conditionally to all hosts or users.

A key feature of `den` is its management of aspect dependencies. When an aspect is resolved, `flake-aspects` includes its class-specific module along with those of its transitive `includes`. `den` extends this by registering special [dependencies](modules/aspects/dependencies.nix) to link hosts and users. For instance, a host's configuration includes contributions from each of its users' aspects, and a user's home configuration includes contributions from its host's aspect, creating a bidirectional flow of settings. This is achieved without recursion by using distinct contexts for each direction.

</details>

<details>
<summary>

### Organization Patterns

> Learn patterns for organizing and reusing aspects.

</summary>

While `den` is unopinionated about organization, these patterns can help structure your aspects for clarity and reuse.

#### Aspect Namespaces

Group related aspects under a single top-level aspect and alias it as a module argument for easier access. The `den.namespace` function streamlines this.

<table>
<tr>
<td>

#### Using local and remote namespaces

```nix
# modules/namespace.nix
{ inputs, ... }:
{
  imports = [ 
    # create local `pro` namespace
    (inputs.den.namespace "pro" true) 
    # mixin remote `pro` from input
    (inputs.den.namespace "pro" inputs.foo)
  ];
}
```

</td>
<td>

#### Directly read and write to namespace

```nix
# modules/my-laptop.nix
{ pro, ... }:
{
  pro.gaming.includes = [ pro.gpu ];
}
```

</td>
</tr>
</table>

#### Angle-Bracket Syntax

For deeply nested aspects, `den` offers an experimental feature to shorten access paths. By bringing `den.lib.__findFile` into scope, you can use angle brackets to reference aspects more concisely.

- `<my-laptop>` resolves to `den.aspects.my-laptop`
- `<my-laptop/gaming>` resolves to `den.aspects.my-laptop.provides.gaming`
- `<den/import-tree/host>` resolves to `den.provides.import-tree.provides.home`
- `<vix/foo/bar>` namespace aware: `den.ful.vix.foo.provides.bar`

This feature is powered by a custom [`__findFile`](nix/den-brackets.nix) implementation. See the [profile example](templates/default/modules/_profile/den-brackets.nix) to learn how to enable it.

#### Parametric Routing

You can use parametric aspects to create routing logic that dynamically includes other aspects based on context. This pattern allows you to build a flexible and declarative dependency tree.

```nix
# modules/routes.nix
{ den, pro, ... }:
let
  # Route to a platform-specific profile
  by-platform = { host }: pro.${host.system} or { };
in 
{
  # Apply routes globally
  den.default.includes = [ by-platform ];
}
```

> You made it to the end! Thanks for reading. I hope you enjoy using `den`. It is feature-complete and unlikely to change.

</details>

### Contributing

Contributions are welcome! Feel free to fix typos, improve documentation, or share ideas in our [discussions](https://github.com/vic/den/discussions).

All PRs are checked against the CI. New features should include a test in `_example/ci.nix`.

To run tests locally:

```console
nix flake check ./checkmate --override-input target .
cd templates/default && nix flake check --override-input den ../..
```
