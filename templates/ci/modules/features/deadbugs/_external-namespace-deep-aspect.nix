{ denTest, inputs, ... }:
{

  flake.tests.deadbugs.namespace-deep-aspect = {

    test-external-flake = denTest (
      {
        den,
        provider,
        igloo,
        ...
      }:
      {
        imports = [
          (inputs.den.namespace "provider" [
            true
            inputs.provider
          ])
        ];
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ provider.tools._.dev._.editors ];
        expr = igloo.programs.vim.enable;
        expected = true;
      }
    );

  };

}
