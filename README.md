# den - Dendritic Nix host configurations.

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

<em><h4>Powerful, minimalistic approach to declaring Dendritic Nix host configurations.</h4></em>

</td>  
<td>

🏠 Concise host definitions ([working example](templates/default/modules/_example/hosts.nix))

```nix
# modules/hosts.nix -- defines a host with single user.
{
  den.x86-64-linux.work-laptop.users.vic = {}; # schema: types.nix
}
```

🧩 [aspect-oriented](https://github.com/vic/flake-aspects) dendritic modules ([working example](templates/default/modules/_example/aspects.nix))

```nix
# modules/work-laptop.nix
{
  flake.aspects = { aspects, ... }: {
    work-laptop = {
      includes = with aspects; [ vpn office secrets.provides.work ];
      darwin = ...; # (see nix-darwin options)
      nixos  = ...; # (see nixos options)
    };
  };
}
```

</td>
</tr>  
</table>

**❄️ Try it now! launch our template VM:**

```console
nix run "github:vic/den?dir=templates/default#vm" --no-write-lock-file
```

or clone it and adapt to your liking:

```console
nix flake init -t github:vic/den
nix run .#vm # launch the VM as you edit
```

## Usage

The [syntax](nix/types.nix) for a Host and its Users is concise and [focused](nix/os-config.nix) on system definition not on their features.

Host and User features are configured by using [flake.aspects](https://github.com/vic/flake-aspects). For global features, this library [adds](nix/aspects-config.nix) `flake.aspects.default.host` and `flake.aspects.default.user`.

The following code example tries to take you into a tour of `den` usage. Remember that you are free to have as many or as few files as you want, the Dendritic pattern imposes no rules on where or how your files named. It is up to you to organize and come up with a good directory structure and aspect organization that make sense to you.

```nix
# modules/hosts.nix -- see <den>/nix/types.nix for schema.
{
  # Most common use is just a oneliner: define a host with a single user.
  # You can nest the definition when needed, eg. to set non-default values.

  den.x86-64-linux.work-laptop.users.vic = {};

  # From this example: `class` is `nixos` (`system` does not end with `darwin`)
  # Inferred aspect-name is `work-laptop` for host, and `vic` for user.

  # `flake.nixosConfigurations.work-laptop` will import `flake.modules.nixos.work-laptop`.
  # from there, the aspects dependency system computes the aggregated module by:
  #
  # - importing `flake.aspects.default.host.nixos` module if any.
  # - calling each of `flake.aspects.default.host.includes` with `{ host }` 
  #   to obtain other aspects.
  # - calling each of `flake.aspects.default.user.includes` with `{ host, user }`
  #   to obtain other aspects.
  # - all aspect dependencies are followed and their nixos modules
  #   are all imported in the final `flake.modules.nixos.work-laptop` module.
  #
  # The same would happen for any other nix class, like `darwin`.

}
```

That's pretty much it, as long as host definition is concerned. Now you need to enhance the host and user aspects using [`flake.aspects`](https://github.com/vic/flake-aspects), refer to its README and tests for usage.

Remember that dendritic aspects are incremental, many different files can contribute to the same aspect. Read [vic](https://github.com/vic)'s [dendritic guide](https://vic.github.io/dendrix/Dendritic.html) for more on this. In our following example, we try to keep things minimal, but files will grow or be split into other modules as you improve them.

Now, lets continue our example by adding some dendritic modules:

```
# modules/host-defaults.nix -- these apply to all hosts
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

# modules/work/features.nix -- add same features to all work laptops
{
  flake.aspects = { aspects, ... }: {
    work-laptop.includes = with aspects; [ vpn meetings office ];
  };
}

# modules/vic/base.nix -- included on all hosts where vic exists
{
  flake.aspects = { aspects, ... }: {
    vic.homeManager = ...; # dot-files, basic environment.
    vic.includes = with aspects; [ 
      tiling-desktop vim-btw secret-vault.provides.vic-personal
    ];
  };
}

# modules/vic/host-user.nix -- routes per host
{
  flake.aspects = { aspects, ... }: {

    # hook into default.host so we can provide the vic user.
    default.host.includes = [ aspects.vic.provides.host-user ];

    vic.provides.host-user = { host, user }:
      if user.userName == "vic"
      then flake.aspects.vic.provides."user-at-${host.hostName}"
      else _: {};

    vic.provides.user-at-work-laptop = _: {
      darwin.system.primaryUser = "vic";
      nixos.users.users.vic = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
    };

  };
}
```
