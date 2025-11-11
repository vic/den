{ lib, ... }:
let

  # Example: configuration that depends on both host and user. provides anytime { user, host } is in context.
  user-to-host-conditional =
    { user, host, ... }:
    if user.userName == "alice" && !lib.hasSuffix "darwin" host.system then
      {
        nixos.programs.tmux.enable = true;
      }
    else
      { };
in
{

  # Example: user provides parametric host configuration.
  den.aspects.alice.includes = [
    user-to-host-conditional
  ];

  perSystem =
    {
      checkCond,
      rockhopper,
      honeycrisp,
      ...
    }:
    {
      checks.alice-os-tmux-enabled-on = checkCond "os tmux for hosts having alice" (
        rockhopper.config.programs.tmux.enable
      );
      checks.alice-os-tmux-enabled-off = checkCond "os tmux for hosts having alice" (
        !honeycrisp.config.programs.tmux.enable
      );

    };

}
