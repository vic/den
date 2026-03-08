{
  perSystem.treefmt.settings.global.excludes = [
    ".github/*TEMPLATE*/*"
    "docs/*"
    "Justfile"
  ];
  perSystem.treefmt.programs.deadnix.enable = false;
  perSystem.treefmt.programs.nixf-diagnose.enable = false;
}
