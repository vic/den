# den - Dendritic nix host configurations.

<p align="right">
  <a href="https://nixos.org/"> <img src="https://img.shields.io/badge/Nix-Flake-informational?logo=nixos&logoColor=white" alt="Nix Flake"/> </a>
  <a href="https://github.com/vic/den/actions">
  <img src="https://github.com/vic/den/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/vic/den" alt="License"/> </a>
</p>

**Try it now! launch our example VM:**

```console
nix run "github:vic/den?dir=templates/default#vm" --no-write-lock-file
```

<table>
<tr>
<td>
<img width="400" height="400" alt="den" src="https://github.com/user-attachments/assets/af9c9bca-ab8b-4682-8678-31a70d510bbb" /> 

</td>  
<td>

Concise host definitions ([example](templates/default/modules/_example/hosts.nix))

```nix
# hosts.nix
{
  den.hosts.my-laptop = {
    system = "x86_64-linux";
    users.vic = { };
  };
}
```

[`flake-aspect`](https://github.com/vic/flake-aspect) powered [dendritic](https://vic.github.io/dendrix/Dendritic.html) modules ([example](templates/default/modules/_example/aspects.nix))

```nix
# aspects.nix
{
  flake.aspects = {
    my-laptop.nixos = ...;
    vic.homeManager = ...;
  };
}
```

</td>
</tr>  
</table>
