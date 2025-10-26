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
    provides.work-laptop = { host, user }: _: {
      darwin.system.primaryUser = user.userName;
      nixos.users.users.vic.isNormalUser = true;
    };
  };
}
```

</td>
</tr>
</table>

## Usage

The syntax for Hosts, Users and standalone Homes is concise and [focused](nix/config.nix) on system definition, not on their features.

Features are configured using [flake.aspects](https://github.com/vic/flake-aspects). For global features, this library [adds](nix/aspects.nix) `flake.aspects.default.host`, `flake.aspects.default.user` and `flake.aspects.default.home`.

The following code example provides a tour of `den`'s usage. Remember that you are free to have as many or as few files as you want; the Dendritic pattern imposes no rules on where your files are located or how they are named. It is up to you to organize and create a directory structure and aspect organization that makes sense for your use case.

```nix
# modules/hosts.nix -- see <den>/nix/types.nix for schema.
{
  # The most common use is a one-liner: defining a host with a single user.
  # You can nest the definition when needed, for example, to set non-default values.
  den.hosts.x86-64-linux.work-laptop.users.vic = {};
}
```

> That's it for the host definition.

For standalone home-manager configurations (without a NixOS/Darwin host):

```nix
# modules/homes.nix -- see <den>/nix/types.nix for schema.
{
  # Multiple homes can share the same aspect.
  # this standalone-darwin-home shares same modules 
  # as the home-managed nixos at work-laptop.
  den.homes.aarch64-darwin.vic = {};
}
```

These will generate `flake.homeConfigurations.vic` entries that can be activated with `home-manager switch --flake .#vic`.

Now you need to enhance the host and user aspects using [`flake.aspects`](https://github.com/vic/flake-aspects). Refer to its README and tests for usage. The rest of this guide is an example of aspect customization.

From our `work-laptop` host example, the `class` is inferred as `nixos` from its `system` name.
The aspect names are `work-laptop` for the host and `vic` for the user.

`flake.nixosConfigurations.work-laptop` will import `flake.modules.nixos.work-laptop`.
The `flake.aspects` system computes the final aggregated module by:

- Using global `flake.aspects.default.host.${host.class}` definitions.
- Calling `flake.aspects.default.host.includes` with `{ host }`
  to obtain `${host.class}` modules from other aspects.
- Calling `flake.aspects.${user.aspect}.provides.${host.aspect}` with `{ host, user }`
  to obtain `${host.class}` modules from other aspects.
- All aspect dependencies are followed, and all `${host.class}` modules
  are collected and imported into the final `flake.modules.nixos.work-laptop` module.

The same process applies to any other host Nix class, like `darwin`.

You can see these dependencies defined at [`aspects.nix`](nix/aspects.nix).

Similarly, user aspects have these dependencies:

- Using global `flake.aspects.default.user.${user.class}` definitions.
- Calling each `flake.aspects.default.user.includes` with `{ host, user }`
  to obtain more `${user.class}` modules from other aspects.

For user-level configs, common classes are `homeManager` or `hjem`.

Remember that dendritic aspects are incremental, and many different files can contribute to the same aspect. Read [vic](https://github.com/vic)'s [dendritic guide](https://vic.github.io/dendrix/Dendritic.html) for more on this. In the following example, we try to keep things minimal, but files will grow or be split into other modules as you improve them.

Now, let's continue our example by adding some dendritic modules:

```nix
# modules/host-defaults.nix -- These apply to all hosts.
{
  flake.aspects.default.host = {
    nixos.system.stateVersion = "25.11";
    darwin.system.stateVersion = 6;
  };
}

# modules/work/thinkpad.nix
{
  flake.aspects.work-laptop.nixos = {
    networking.hostName = "penguin";
    imports = [ ./_thinkpad/hardware.nix ./_thinkpad/filesystems.nix ];
  };
}

# modules/work/macbook.nix
{
  flake.aspects.work-laptop.darwin = {
    networking.hostName = "fruit";
  };
}

# modules/work/features.nix -- Add the same features to all work laptops.
{
  flake.aspects = { aspects, ... }: {
    work-laptop.includes = with aspects; [ vpn meetings office ];
  };
}

# modules/vic/base.nix -- Included on all hosts where vic exists.
{
  flake.aspects = { aspects, ... }: {
    vic.homeManager = ...; # dot-files, basic environment.
    vic.includes = with aspects; [
      tiling-desktop vim-btw secret-vault.provides.vic-personal
    ];
  };
}

# modules/vic/at-work-laptop.nix
{
  flake.aspects.vic.provides.work-laptop = {host, user}: _: {
    darwin.system.primaryUser = "vic";
    nixos.users.users.vic = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
}
```

### Freeform Attributes

The `host`, `user`, and `home` configuration types support freeform attributes, meaning you can add any custom attributes you need beyond the standard options. These custom attributes are accessible in aspect provider functions registered in `flake.aspects.default.{home,user,host}` and in aspect provides functions like `flake.aspects.${user.aspect}.provides.${host.aspect}`. This allows you to pass additional metadata or configuration options that your aspects can use when building the final configuration.

### Custom os/home factories

Each `host`/`home` configuration has an optional [`instantiate`](https://github.com/vic/den/blob/2480d18/nix/types.nix#L36) function. You can set this attribute to support new types of OS systems or new types of standalone homes.

As an example lets suppose we need a specific input name (e.g, `nixpkgs-stable` etc) for a particular host:

```nix
# modules/wsl-instantiate.nix
{ inputs, ... }:
{
  flake.inputs.nixpkgs-stable.url = "https://channels.nixos.org/nixos-25.05/nixexprs.tar.xz";
  flake.inputs.nixos-wsl.inputs.nixpkgs.follows = "nixpkgs-stable";

  # see <den>/nix/config.nix: `osConfiguration`, types.nix: `hostType.instantiate`
  den.hosts.x86_64-linux.my-wsl.instantiate = inputs.nixpkgs-stable.lib.nixosSystem;
}
```

Another use case is using `extraSpecialArgs` in a standalone-home. Note that using `specialArgs` or `extraSpecialArgs` is an anti-pattern in Dendritic nix, most of the time there's no need for using special args since all dendritic modules are flake-parts modules and all have access to inputs, perSystem, etc. However, if for whatever reason you have _no way around_, you can use the instantiate function to pass special args, just be very very cautious of doing this.

```nix
{ inputs, self, ... }: 
{
  # $ home-manager switch --flake .#vic@work-laptop
  den.homes.x86_64-linux."vic@work-laptop" = {
    aspect = "vic"; # re-use same aspect as work-laptop.users.vic
    # see config.nix: `homeConfiguration`, types.nix: `homeType.instantiate`
    instantiate = { pkgs, modules }: inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs modules;
      # example: both os-hm and standalone-hm configs depend on `os-config` arg.
      extraSpecialArgs.os-config = self.nixosConfigurations.work-laptop.config;
    };
  };
}
```
