{ inputs, ... }:
{
  # Example: adelie host using github:nix-community/NixOS-WSL
  den.aspects.adelie.nixos = {
    imports = [ inputs.nixos-wsl.nixosModules.default ];
    wsl.enable = true;
  };
}
