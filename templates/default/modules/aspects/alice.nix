{ den, ... }:
{
  den.aspects.alice = {
    # You can include other aspects, in this case some
    # den included batteries that provide common configs.
    includes =
      let
        # deadnix: skip # demo: enable <> on lexical scope
        inherit (den.lib) __findFile;

        customVim.homeManager =
          { pkgs, ... }:
          {
            programs.vim.enable = true;
            programs.vim.package = pkgs.neovim;
          };
      in
      [
        customVim
        <eg/autologin>
        <den/primary-user> # alice is admin always.
        (<den/user-shell> "fish") # default user shell
      ];

    # Alice configures NixOS hosts it lives on.
    nixos =
      { pkgs, ... }:
      {
        users.users.alice = {
          description = "Alice Cooper";
          packages = [ pkgs.vim ];
        };
      };

    # Alice home-manager.
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.htop ];
      };

    # <user>.provides.<host>, via eg/routes.nix
    provides.igloo =
      { host, ... }:
      {
        nixos.programs.nh.enable = host.name == "igloo";
      };
  };
}
