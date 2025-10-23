# den - Dendritic Nix host configurations.

<table>
<tr>
<td>

<em>A minimalistic yet powerful approach to declaring Dendritic Nix host configurations.</em>

<p align="left">
  <a href="https://vic.github.io/dendrix/Dendritic.html"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
</p>

<img width="400" height="400" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" /> 

</td>  
<td>

> Concise host definitions ([example](templates/default/modules/_example/hosts.nix))

```nix
# modules/hosts.nix
{
  den.hosts.work-laptop = {
    system = "x86_64-linux";
    users.vic = { };
  };
}
```

> [aspect-oriented](https://github.com/vic/flake-aspects) modules ([example](templates/default/modules/_example/aspects.nix))

```nix
# modules/work-laptop.nix
{
  flake.aspects.work-laptop = {
    nixos.system.stateVersion = "25.11";
    darwin.system.stateVersion = 6;
  };
}

# modules/vic.nix
{
  flake.aspects.vic = {
    darwin.system.principalUser = "vic";
    nixos.users.users.vic.isNormalUser = true;
  };
}
```

</td>
</tr>  
</table>

**Try it now! launch our template VM:**

```console
nix run "github:vic/den?dir=templates/default#vm" --no-write-lock-file
```

## Usage

The [syntax](nix/types.nix) for a host and its users is concise and [focused](nix/os-config.nix) on declaration. host/user features are handled by [aspects](nix/aspects-config.nix).

```nix
# modules/gaming/host.nix
{
  den.hosts.gaming-tower = { 
    system = "x86_64-linux"; # discovered as nixos, default aspect name: gaming-tower.
    users.vic.aspect = "vic@gaming-tower"; # custom aspect name for user vic.
  }
}
```

And then you create as many other dendritic modules to extend the features of `gaming-tower` and `vic`.

```nix
# modules/gaming/os.nix
{
  flake.aspects.gaming-tower = {
    nixos = {
      # enable steam, enable firewall ports, etc.
    };
  }
}
```

```nix
# modules/gaming/vic.nix
{
  flake.aspects = { aspects, ... }: {
    "vic@gaming-tower".includes = [ aspects.vic ];
    "vic@gaming-tower".nixos = {
      # extend the normal `vic` aspect with gaming features.
    };
  };
}
```
