{ inputs, den, ... }:
{
  den.hosts.x86_64-linux.igloo.users.tux = { };

  # See [Debugging Tips](https://den.oeiuwq.com/debugging.html)
  flake.den = den;

  # Use aspects to create a **minimal** bug reproduction
  den.aspects.testing =
    { user, ... }@ctx:
    builtins.trace ctx.host.hostName {
      homeManager.programs.vim.enable = user.userName == "tux";
    };

  den.aspects.igloo.includes = [ den.aspects.testing ];

  flake.tests."test it works" =
    let
      igloo = inputs.self.nixosConfigurations.igloo.config;
      tux = igloo.home-manager.users.tux;

      expr = tux.programs.vim.enable;
      expected = true;
    in
    {
      inherit expr expected;
    };
}
