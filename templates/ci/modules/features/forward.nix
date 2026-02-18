{ denTest, ... }:
{
  flake.tests.forward = {

    test-forward-custom-class-to-nixos = denTest (
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
            fromClass = _: "custom";
            intoClass = _: "nixos";
            intoPath = _: [ ];
            fromAspect = _: lib.head aspect-chain;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          includes = [ forwarded ];
          custom.networking.hostName = "from-custom-class";
        };

        expr = igloo.networking.hostName;
        expected = "from-custom-class";
      }
    );

    test-forward-into-subpath = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      let
        fwdModule = {
          options.items = lib.mkOption { type = lib.types.listOf lib.types.str; };
        };

        forwarded =
          { class, aspect-chain }:
          den._.forward {
            each = lib.singleton class;
            fromClass = _: "src";
            intoClass = _: "nixos";
            intoPath = _: [ "fwd-box" ];
            fromAspect = _: lib.head aspect-chain;
          };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          includes = [ forwarded ];
          nixos.imports = [
            { options.fwd-box = lib.mkOption { type = lib.types.submoduleWith { modules = [ fwdModule ]; }; }; }
          ];
          nixos.fwd-box.items = [ "from-nixos-owned" ];
          src.items = [ "from-src-class" ];
        };

        expr = lib.sort (a: b: a < b) igloo.fwd-box.items;
        expected = [
          "from-nixos-owned"
          "from-src-class"
        ];
      }
    );

  };
}
