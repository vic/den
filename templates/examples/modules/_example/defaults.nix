# User TODO: Remove this file.
{
  # default aspect can be used for global static settings.
  den.default = {
    # static values.
    darwin.system.stateVersion = 6;
    nixos.system.stateVersion = "25.05";
    homeManager.home.stateVersion = "25.05";

    # these defaults are set for checking with CI.
    nixos.programs.vim.enable = true;
    darwin.programs.zsh.enable = true;
  };
}
