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

- Dendritic: Same concern over different classes.

- Small and [DRY](modules/aspects/provides/unfree.nix)<br>
  [`class` generic](modules/aspects/provides/primary-user.nix) Nix configurations.

- Context-Aware aspects.<br>[Parametric](modules/aspects/provides/define-user.nix) over `host`/`home`/`user`.

- Stop copying and **share**(tm)<br>
  aspects across systems and Dendritic repos.

- Bidirectional [configurations](modules/aspects/dependencies.nix).<br>
  Users can contribute to their Host configuration and the other way around.

- Custom factories and output attributes.<br>
  Support any new `class` of Nix configurations.

- Use your `stable`/`unstable` input channels.

- _Freeform_ `host`/`user`/`host` [schemas](modules/_types.nix).<br>
  Avoid the need for using `specialArgs`.

- Multi-platform, Multi-tenant hosts.

- Reuse aspects across hosts, OS, homes.

- [Batteries Included](modules/aspects/provides/)<br>
  Opt-in and replaceable.

- [Well tested](templates/default/modules/_example/ci.nix)<br>
  Suite exercises all [features with examples](templates/default/modules/).

Need more batteries? See [vic/denful](https://github.com/vic/denful).

Join the community [discussion](https://github.com/vic/den/discussions). Ask questions, share how you use `den`.

</div>
</td>
<td>

🏠 Concise definitions of
[Hosts, Users](templates/default/modules/_example/hosts.nix) and [Standalone-Homes](templates/default/modules/_example/homes.nix).

See [\_types.nix](modules/_types.nix) for complete schema.

```nix
# modules/hosts.nix
{
  # This example defines the following aspects:
  #  den.aspects.my-laptop and den.aspects.vic
  # standalone-hm and nixos-hm share vic aspect

  # $ nixos-rebuild switch --flake .#my-laptop
  den.hosts.x86-64-linux.my-laptop.users.vic = {}; 
  # $ home-manager switch --flake .#vic
  den.homes.aarch64-darwin.vic = { };

  # That's it! Now lets attach configs via aspects
}
```

🧩 [Aspect-oriented](https://github.com/vic/flake-aspects) configurations. ([example](templates/default/modules/_example/aspects.nix))

```nix
# modules/my-laptop.nix -- Attach behaviour to host
{ den, ... }:
{
  den.aspects.my-laptop = {
    # dependency graph on other shared aspects
    includes = [
      # my parametric { host } => aspect
      den.aspects.vpn # setups firewall/daemons
      # opt-in, replaceable batteries included
      den.provides.home-manager
    ];
    # provide same features at any OS/platform
    nixos  = ...; # (see nixos options)
    darwin = ...; # (see nix-darwin options)
    # contrib hm-config to all my-laptop users
    homeManager.programs.vim.enable = true;
  };
}

# modules/vic.nix -- Reused in OS/standalone HM
{ den, ... }:
{
  den.aspects.vic = {
    homeManager = ...; # (see home-manager options)
    # user can contrib to hosts where it lives
    nixos.users.users.vic.description = "oeiuwq";
    includes = [ 
      den.aspects.tiling-wm 
      # parametric { user, host } => aspect
      den.provides.primary-user # vic is admin
    ];
  };
}
```

For real-world examples, see [`vic/vix`](https://github.com/vic/vix/tree/den)
or try this [GH search](https://github.com/search?q=vic%2Fden+language%3ANix&type=code).

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

Our [default template](templates/default) provides a [layout](templates/default/modules/_profile/) for quickstart.

</td>
</tr>
</table>

You are done! You know everything there is to know about `den` for creating configurations with it.

However, if you want to learn more about how it works, I have tried to document some other topics in collapsible sections to avoid distraction from the introduction.

<details>
<summary>

# Basic Concepts and Patterns.

> Learn about aspects, static and parametric. Default aspects and dependencies.

</summary>

There are two fundamental types of aspects in `den`, _static_ and _parametric_.

<table>
<tr>
<td>

#### **Static** aspects are just attribute sets

```nix
# An aspect is a collection of many
# Nix configuration modules, each having
# a different `class`.
den.aspects.my-laptop = {
  nixos  = { };
  darwin = { };
  homeManager = { };
  nixVim = { };
  nixDroid = { };

  # aspects can be nested via `provides`
  # forming a tree structure.
  provides.gaming = {
    nixos = { };
    nixDroid = { };

    # aspects can also `include` others
    # forming a graph of dependencies
    includes = [
      # gaming.nixos module will mixin
      # nvidia-gpu.nixos module if any.
      den.aspects.nvidia-gpu
    ];
  };

};
```

> **TIP**
> **`_`** is an alias for `provides`. In many examples you will see `foo._.bar._.baz` instead of `foo.provides.bar.provides.baz`.

> **NOTE**
> Den provides an [__angle-brackets__](https://fzakaria.com/2025/08/10/angle-brackets-in-a-nix-flake-world) **experimental feature** that allows even shorter syntax for deep `.provide.` access.
> See [import-non-dendritic.nix](https://github.com/vic/den/pull/38/files) for an example usage.

</td>
<td>

#### **Parametric** aspects are just functions.

```nix
# The convention is to always use named args.
# These required args is the **context** the
# aspect needs to provide configuration.
hostParametric = { host }: {
  nixos.networking.hostName = host.hostName;

  # A parametric aspect can also ask other
  # aspects for context-aware configurations.
  # Here, we ask two other parametric aspects
  # given the `{ host, gaming }` context.
  includes = let 
    context.host = host;
    context.gaming.emulators = [ "nes" ];
  in map (f: f context) [
    den.default
    den.aspects.gaming-platform
  ];
};
```

#### Important **context** variants in `den`.

Den uses the following contexts by default.

The aspect system is not limited to these,<br>
but these are used to describe [dependencies](modules/aspects/dependencies.nix)<br>
between hosts/users, homes and default configs.

- `{ host }` - For host _OS_ level configs.
- `{ user, host }` - For user _Home_ level configs.
- `{ home }` - For standalone _Home_ configs.

</td>
</tr>
</table>

### The Default aspect and default Dependencies

Den has an special aspect at `den.default` that serves for global configuration. `den.default` is **included by default** in all *Hosts*, *Users* and *Homes*. For example a Home configuration invokes `den.default { inherit home; }`, to obtain the aggregated defaults for home contexts.

<table>
<tr>
<td>

#### Registering defaults values

```nix
{
  # you can assign static values directly.
  den.default.nixos = {
    system.stateVersion = "25.11";
  };

  # you can also include other aspects
  den.default.includes = [
    { darwin.system.stateVersion = 6; }
  ]
}
```

It is possible to also register context-aware parametric aspects in `den.defaults`. This is how you can provide a default to all hosts or users that match a condition.

```nix
# This example is split to aid reading.
let
  hasOneUser = host:
    length (attrNames host.users) == 1;
  hasUser = host: user:
    hasAttr user.name host.users;
  makeAdmin = user: {
    nixos.users.users.${user.name} = {
      extraGroups = [ "wheel" ]; 
    };
  };

  # IFF host has ONE user, make it admin
  single-user-is-admin = { host, user }: 
    if hasOneUser host && hasUser host user
    then makeAdmin user else { };
in
{
  den.default.includes = [
    # will be called *ONLY* on when the
    # `{ host, user }` context is used.
    single-user-is-admin
  ];
}
```

#### Custom parametric providers.

The following is the code for how `den.default` is
defined.

```nix
{ den, ... }: {
  den.default.__functor = den.lib.parametric true;
}
```

You can do the very same for other aspects of you
that can have context-aware aspects in their `.includes`.

```nix
{ den, ...}: {
  den.aspects.gaming.__functor = den.lib.parametric true;

  # any other file can register gaming aspects
  den.aspects.gaming.include = [
    ({ emulation }: {
      nixos = ...;
      includes = [ den.aspects.steam ];
    })

    { nixos = ...; } # always included
    ({ gpu }: { }) # non-match on my-laptop
  ];

  # then you can depend on the gaming aspect:
  den.aspects.my-laptop.includes = [ 
    (den.aspects.gaming { emulation = "neogeo"; })
  ];

}
```

For more examples on parametric aspects explore our [batteries](modules/aspects/provides/).

> Use the source, Luke!

</td>

<td>

#### Aspect dependencies

Accessing an aspect module causes `flake-aspects` to resolve it
by including the aspect's own class module and the same-class module
of all its transitive includes.

Aditional to this, `den` registers some special [dependencies](modules/aspects/dependencies.nix)
designed to aid on Den particular use case: Host/Users, Homes.

###### Host dependencies

Host also include `den.aspects.<host> { inherit host; }` meaning
all included parametric aspects have an opportunity to produce
aditional configurations for the host.

Also for each user, `den.aspects.<user> { inherit host user; }`
is called. So `den.aspects.alice.nixos` can provide config to
all hosts where alice lives. And also has the opportunity to
register parametric aspects on `alice.provides` that inspect
the host attribute to contionally produce other aspects.

###### User dependencies

User modules are read from [os-home](modules/aspects/provides/home-manager.nix) configurations.

It basically invokes `den.aspects.<user> { inherit host user; }` but
this time the host also contributes back generic configs to the users.
If you are wondering how this is not recursive, the answer is by using
our _contexts_, user-to-host dependencies start with a `{ host }` context,
while host-to-user dependencies start with a `{ user, host }` context, and
even when both are given to `den.aspects.<user> ctx` the results are
non recursive.

A user also depends on `den.default { inherit host user; }`.

###### Home dependencies

Home just uses its own module, its includes, and invokes `den.default { inherit home; }`.

</td>

</tr>
</table>

</details>

<details>
<summary>

# Aspect Organization Patterns

> Learn about organizing patterns for reuse.

</summary>

No two nix configurations are the same. We all tend to organize things as we feel better.
This section will try to outline some hints on possible ways to organize aspects, none
of this is mandatory, and indeed you are encouraged to explore and [share](https://github.com/vic/den/discussions) your own patterns and insights.

#### Having a _namespace_ of aspects.

The first principle is using `.provides.` (aka [`._.`](https://github.com/vic/den/discussions/34)) to nest your aspects as they make sense for you.

Unlike normal flake-parts, where modules are _flat_ and people tend to use names like `flake.modules.nixos."host/my-laptop"` or `nixos."feature/gaming"` to avoid collission, in `den` you have a proper tree structure.

I (_vic_), use an aspect `vix` for all _features_ on my system, and from there I create sub-aspects.

Because writing `den.aspects.vix._.gaming._.emulation` tends to be repetitive, I use the following `vix` alias as module argument.

> This pattern is also shown in the default template, under [`_profile`](templates/default/modules/_profile/).

<table>
<tr>
<td>

```nix
# modules/namespace.nix
{ config, ... }:
{
  den.aspects.vix.provides = { };
  _module.args.vix = # up to provides
    config.den.aspects.vix.provides;
}
```

</td>
<td>

```nix
# modules/my-laptop.nix
{ vix, ... }:
{
  vix.gaming = {
    _.steam.includes = [ 
      vix.gpu 
      vix.performance-profile 
    ];
  };
}
```

See [real-life example from vic/vix](https://github.com/vic/vix/blob/den/modules/hosts/nargun.nix)

</td>
</tr>
</table>

#### Using parametric aspects to route configurations.

The following example routes configurations into the `vix` namespace.
This is just an example of using parametric aspects to depend on other
aspects in any part of the tree.

<table>
<tr>
<td>

```nix
# modules/routes.nix
{ den, ... }:
let
  noop = _: { };

  by-platform-config = { host }:
    vix.${host.system} or noop;

  user-provides-host-config = { user, host }:
    vix.${user.aspect}._.${host.aspect} or noop;

  host-provides-host-config = { user, host }:
    vix.${host.aspect}._.${user.aspect} or noop;

  route = locator: { user, host }@ctx: 
    (locator ctx) ctx;
in 
{
  den.aspects.routes.__functor = 
    den.lib.parametric true;
  den.aspects.routes.includes = 
    map route [
      user-provides-host-config
      host-provides-user-config
      by-platform-config
    ];
}
```

</td>
<td>

```nix
{
  # for all darwin hardware
  vix.aarch64-darwin = { host }: {
    darwin = ...; 
  };

  # config bound to vic user 
  # on my-laptop host.
  vix.vic.provides.my-laptop = 
    { host, user }: {
      nixos = ...;
    };
}
```

Use your imagination, come up with
an awesome Dendritic setup that suits you.

</td>
</tr>
</table>

> You made it to the end!, thanks for reading to this point.
> I hope you enjoy using `den` as much as I have done writing it and have put dedication
> on it for being high quality-nix for you. \<3.
> I feel like den is now feature complete, and it will not likely change.

</details>

### Contributing.

Yes, please, anything!. From fixing my bad english and typos, to sharing your ideas and experience with `den` in our discussion forums. Feel free to participate and be nice with everyone.

PRs are more than welcome, the CI runs some checks that verify nothing (known) is broken. Any new feature needs a test in `_example/ci.nix`.

If you need to run the test suite locally:

```console
$ nix flake check ./checkmate --override-input target .
$ cd templates/default && nix flake check --override-input den ../..
```
