# User TODO: Remove this file.
{
  # default.{host,user,home} aspects can be used for global static settings.
  den.default = {
    # static values.
    host.darwin.system.stateVersion = 6;
    host.nixos.system.stateVersion = "25.05";
    user.homeManager.home.stateVersion = "25.05";
    home.homeManager.home.stateVersion = "25.05";

    # these defaults are set for checking with CI.
    user.nixos.programs.vim.enable = true;
    user.darwin.programs.zsh.enable = true;
    user.homeManager.programs.fish.enable = true;
  };
}
