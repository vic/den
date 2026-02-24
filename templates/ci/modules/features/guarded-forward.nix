{ denTest, ... }:
let
  imperModule =
    { lib, ... }:
    {
      options.impermanence = lib.mkOption {
        type = lib.types.submoduleWith {
          modules = [
            {
              options.foo = lib.mkOption {
                type = lib.types.int;
                default = 0;
              };
            }
          ];
        };
        default = { };
      };
    };
in
{
  flake.tests.guarded-forward = {

    test-guard-applies-when-target-exists = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      let
        forwarded =
          { class, aspect-chain }:
          den._.forward {
            each = lib.singleton class;
            fromClass = _: "imper";
            intoClass = _: "nixos";
            intoPath = _: [ "impermanence" ];
            fromAspect = _: lib.head aspect-chain;
            guard = { options, ... }: options ? impermanence;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          includes = [ forwarded ];
          nixos.imports = [ imperModule ];
          imper.foo = 42;
        };

        expr = igloo.impermanence.foo;
        expected = 42;
      }
    );

    test-guard-skips-when-target-missing = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      let
        forwarded =
          { class, aspect-chain }:
          den._.forward {
            each = lib.singleton class;
            fromClass = _: "imper";
            intoClass = _: "nixos";
            intoPath = _: [ "impermanence" ];
            fromAspect = _: lib.head aspect-chain;
            guard = { options, ... }: options ? impermanence;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          includes = [ forwarded ];
          imper.foo = 42;
        };

        expr = igloo.networking.hostName;
        expected = "nixos";
      }
    );

  };
}
