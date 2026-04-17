{
  perSystem.treefmt.settings.global.excludes = [
    ".github/*TEMPLATE*/*"
    "docs/*"
    "Justfile"
    "AGENT*.md"
    "*.txt"
    "ci.bash"
  ];
  perSystem.treefmt.programs.deadnix.enable = false;
  perSystem.treefmt.programs.nixf-diagnose.enable = false;
}
