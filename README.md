# den - Dendritic Nix host configurations.

<p align="right">
  <a href="https://vic.github.io/dendrix/Dendritic.html"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
</p>

<table>
<tr>
<td style="max-width: 400px;">

<em>A minimalistic yet powerful approach to declaring Dendritic Nix host configurations.</em>

<img width="400" height="400" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" /> 

**Try it now! launch our template VM:**

```console
nix run "github:vic/den?dir=templates/default#vm" --no-write-lock-file
```

</td>  
<td>

> Concise host definitions ([example](templates/default/modules/_example/hosts.nix))

```nix
# modules/hosts.nix
{
  den.hosts.my-laptop = {
    system = "x86_64-linux";
    users.vic = { };
  };
}
```

> [aspect-oriented](https://github.com/vic/flake-aspects) modules ([example](templates/default/modules/_example/aspects.nix))

```nix
# modules/my-laptop.nix
{
  flake.aspects.my-laptop = {
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

## Usage

The [syntax](nix/types.nix) for a host and its users is concise and [focused](nix/os-config.nix) on declaration. host/user features are handled by [aspects](nix/aspects-config.nix).

```nix
# modules/hosts/gaming-laptop.nix
{
  den.hosts.gaming-laptop = { 
    system = "x86_64-linux"; # discovered as nixos, default aspect name: gaming-laptop.
    users.vic.aspect = "vic@gaming-laptop"; # custom aspect name for user vic.
  }
}
```

And then you create as many other dendritic modules to extend the features of `gaming-laptop` and `vic`.

```nix
# modules/gaming/gaming-laptop.nix
{
  flake.aspects.gaming-laptop = {
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
    "vic@gaming-laptop".includes = [ aspects.vic ];
    "vic@gaming-laptop".nixos = {
      # extend the normal `vic` aspect with gaming features.
    };
  };
}
```
