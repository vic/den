{
  config,
  lib,
  den,
  inputs,
  options,
  ...
}:
let
  osFwd =
    { host }:
    den._.forward {
      each = lib.optional (host.intoAttr != [ ]) true;
      fromClass = _: host.class;
      intoClass = _: "flake";
      intoPath = _: [ "flake" ];
      fromAspect = _: den.ctx.host { inherit host; };
      mapModule =
        _: module:
        lib.setAttrByPath host.intoAttr (
          host.instantiate {
            modules = [
              module
              { nixpkgs.hostPlatform = lib.mkDefault host.system; }
            ];
          }
        );
    };

  hmFwd =
    { home }:
    den._.forward {
      each = lib.optional (home.intoAttr != [ ]) true;
      fromClass = _: home.class;
      intoClass = _: "flake";
      intoPath = _: [ "flake" ];
      fromAspect = _: den.ctx.home { inherit home; };
      mapModule =
        _: module:
        lib.setAttrByPath home.intoAttr (
          home.instantiate {
            pkgs = home.pkgs;
            modules = [ module ];
          }
        );
    };

  systemOutputFwd =
    { system, output }:
    { class, aspect-chain }:
    den._.forward {
      each = lib.optional (class == "flake") output;
      fromClass = _: output;
      intoClass = _: "flake";
      intoPath = _: [
        "flake"
        output
        system
      ];
      guard = _: has-flake-output output;
      adaptArgs = _: { pkgs = inputs.nixpkgs.legacyPackages.${system}; };
      fromAspect = _: lib.head aspect-chain;
    };

  ctx.flake.into.flake-system = _: map (system: { inherit system; }) den.systems;

  ctx.flake-system.into.flake-os =
    { system }: map (host: { inherit host; }) (builtins.attrValues den.hosts.${system} or { });
  ctx.flake-system.provides.flake-os = osFwd;

  ctx.flake-system.into.flake-hm =
    { system }: map (home: { inherit home; }) (builtins.attrValues den.homes.${system} or { });
  ctx.flake-system.provides.flake-hm = hmFwd;

  systemOutput = output: { system }: lib.singleton { inherit system output; };

  ctxSystemOuts =
    let
      outputs = [
        "packages"
        "apps"
        "checks"
        "devShells"
        "legacyPackages"
      ];

      ctxs = map (output: {
        flake-system.into."flake-${output}" = systemOutput output;
        flake-system.provides."flake-${output}" = systemOutputFwd;
      }) outputs;
    in
    ctxs;

  flakeModule = den.lib.aspects.resolve "flake" (den.ctx.flake { });

  systemsOpt = lib.mkOption {
    default =
      let
        sys = config.systems or (lib.unique (lib.attrNames den.hosts) ++ (lib.attrNames den.homes));
      in
      if sys == [ ] then lib.systems.flakeExposed else sys;
    type = lib.types.listOf lib.types.str;
  };

  flake =
    (lib.evalModules {
      modules = [
        flakeModule
        inputs.den.flakeOutputs.flake
      ];
      specialArgs.inputs = inputs;
    }).config.flake;

  has-flake-output =
    output: ((options.flake.type.getSubOptions or (_: options.flake)) { }) ? ${output};
  no-flake-parts = !inputs ? flake-parts;

in
{
  imports = lib.optional no-flake-parts inputs.den.flakeOutputs.flake;
  options.den.systems = systemsOpt;
  config.den.ctx = lib.mkMerge (ctxSystemOuts ++ [ ctx ]);
  config.flake = flake;
}
