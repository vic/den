# den - Dendritic Nix host configurations.

<p align="right">
  <a href="https://vic.github.io/dendrix/Dendritic.html"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
</p>

A minimalistic approach to declaring Dendritic Nix host configurations.

<table>
<tr>
<td width="50%">
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

## Core concepts

## Getting Started.
