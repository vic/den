{
  # autologin is context-aware, parametric aspect.
  # it applies only if the context has at least { user }
  # meaning that has access to user data
  eg.autologin =
    { user, ... }:
    {
      nixos =
        { config, lib, ... }:
        lib.mkIf config.services.displayManager.enable {
          services.displayManager.autoLogin.enable = true;
          services.displayManager.autoLogin.user = user.userName;
        };
    };
}
