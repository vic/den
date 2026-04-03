{
  den,
  lib,
  inputs,
  config,
  ...
}:
{
  systems = lib.systems.flakeExposed;

  # Some third-party flake-parts modules for demo purposes.
  # Read their documentation at https://flake.parts for usage.
  imports = [
    inputs.devshell.flakeModule
    inputs.files.flakeModules.default
    inputs.nix-topology.flakeModule
    inputs.nix-unit.modules.flake.default
    inputs.pkgs-by-name-for-flake-parts.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  # some globals
  perSystem = {
    pkgsDirectory = ../packages;
    nix-unit = {
      allowNetwork = true;
      inputs = inputs;
    };
  };

  # den.ctx.flake-parts transformations define which
  # custom classes exist and where to read them.
  den.ctx.flake-parts.into = _: {

    # Read flake-parts classes from hosts and their includes
    host = map (host: { inherit host; }) (
      builtins.concatMap builtins.attrValues (builtins.attrValues den.hosts)
    );

    # Our custom flake-parts perSystem classes.
    # These are partial params for `den._.forward`.
    # See ./perSystem-forward.nix
    flake-parts-system = [

      # A class for flake-parts' perSystem.packages
      # NOTE: this is different from Den's flake-packages class.
      {
        fromClass = _: "packages";
      }

      {
        fromClass = _: "files";
      }

      # a default `devshell` class
      {
        fromClass = _: "devshell";
        intoPath = _: [
          "devshells"
          "default"
        ];
      }

      {
        fromClass = _: "treefmt";
      }

      {
        fromClass = _: "tests";
        intoPath = _: [
          "nix-unit"
          "tests"
        ];
        # test helpers
        adaptArgs =
          args:
          let
            igloo = config.flake.nixosConfigurations.igloo.config;
            tux = igloo.users.users.tux;
          in
          args.config.allModuleArgs // { inherit igloo tux; };
      }
    ];
  };

}
