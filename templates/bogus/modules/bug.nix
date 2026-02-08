{
  inputs,
  den,
  lib,
  ...
}:
{
  den.hosts.x86_64-linux.igloo.users.tux = { };

  den.aspects.igloo.includes = [ den.aspects.testing ];
  # Use aspects to create a **minimal** bug reproduction
  den.aspects.testing =
    { user, ... }@ctx:
    builtins.trace ctx.host.hostName {
      homeManager.programs.vim.enable = user.userName == "tux";
    };

  # `nix-unit --flake .#.tests.systems`
  # `nix eval .#.tests.testItWorks`
  flake.tests.testItWorks =
    let
      igloo = inputs.self.nixosConfigurations.igloo.config;
      tux = igloo.home-manager.users.tux;

      expr = tux.programs.vim.enable;
      expected = true;
    in
    {
      inherit expr expected;
    };

  # See [Debugging Tips](https://den.oeiuwq.com/debugging.html)
  flake.den = den;
  # `nix eval .#.value`
  flake.value =
    let
      aspect = den.aspects.testing {
        user.userName = "tux";
        host.hostName = "fake";
      };
      modules = [
        (aspect.resolve { class = "homeManager"; })
        { options.programs = lib.mkOption { }; }
      ];
      evaled = lib.evalModules { inherit modules; };
    in
    evaled.config;

}
