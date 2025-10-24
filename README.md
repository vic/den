# den - Dendritic Nix Host Configurations

<p align="right">
  <a href="https://vic.github.io/dendrix/Dendritic.html"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
</p>

<table>
<tr>
<td>

<img width="400" height="400" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" />

<em><h4>A refined, minimalistic approach to declaring Dendritic Nix host configurations.</h4></em>

**❄️ Try it now! Launch our template VM:**

```console
nix run github:vic/den
```

Or clone it and run the VM as you edit

```console
nix flake init -t github:vic/den
nix run .#vm
```

Need more batteries? see [vic/denful](https://github.com/vic/denful)

</td>
<td>

🏠 Concise host definitions ([example](templates/default/modules/_example/hosts.nix))

```nix
# modules/hosts.nix -- see schema at nix/types.nix
{
  # Define a host with a single user:
  den.hosts.x86-64-linux.work-laptop.users.vic = {};

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

# modules/vic.nix -- see <den>/nix/aspects.nix
{
  flake.aspects.vic = {
    includes = with flake.aspects; [ tiling-wm ];
    homeManager = ...;
    nixos = ...;

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

The [syntax](nix/types.nix) for a Host and its Users is concise and [focused](nix/os-config.nix) on system definition, not on their features. Standalone home configurations are managed via [home-config.nix](nix/home-config.nix).

Host and User features are configured using [flake.aspects](https://github.com/vic/flake-aspects). For global features, this library [adds](nix/aspects-config.nix) `flake.aspects.default.host` and `flake.aspects.default.user`.

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
  # Define standalone home configurations for any system.
  den.homes.x86-64-linux.vic = {};
  
  # Multiple homes can share the same aspect.
  den.homes.aarch64-darwin.vic = {};
}
```

These will generate `flake.homeConfigurations.vic` entries that can be activated with `home-manager switch --flake .#vic`.

Now you need to enhance the host and user aspects using [`flake.aspects`](https://github.com/vic/flake-aspects). Refer to its README and tests for usage. The rest of this guide is an example of aspect customization.

From our example, the `class` is inferred as `nixos` from its `system` name.
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

You can see these dependencies defined at [`aspects-config.nix`](nix/aspects-config.nix).

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
