{ denTest, inputs, ... }:
{

  flake.tests.deadbugs.namespace-deep-aspect = {

    test-tools-has-underscore = denTest (
      { provider, ... }:
      {
        imports = [
          (inputs.den.namespace "provider" [
            true
            inputs.provider
          ])
        ];
        expr = provider.tools ? _;
        expected = true;
      }
    );

    test-dev-has-underscore = denTest (
      { provider, ... }:
      {
        imports = [
          (inputs.den.namespace "provider" [
            true
            inputs.provider
          ])
        ];
        expr = provider.tools._.dev ? _;
        expected = true;
      }
    );

    test-external-flake = denTest (
      {
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

    test-functor-atLeast-fires-with-host-context = denTest (
      {
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
        den.aspects.igloo.includes = [ provider.tools._.dev._.host-stamp ];
        expr = igloo.environment.sessionVariables.PROVIDER_HOST;
        expected = "igloo";
      }
    );

    test-functor-exactly-fires-only-in-user-context = denTest (
      {
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
        den.aspects.igloo.includes = [ provider.tools._.dev._.user-stamp ];
        expr = igloo.users.users.tux.description;
        expected = "user-of-igloo";
      }
    );

  };

}
