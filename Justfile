system := `nix-instantiate --eval --raw -E builtins.currentSystem`

help:
  just -l

check-all:
  nix-build ./templates/noflake --no-out-link -A flake.nixosConfigurations.igloo
  just all check
  just unit

update-all:
  cd templates/noflake && npins update den
  just all update

docs:
  cd docs && pnpm run dev

ci test="" *args:
  just nix-unit ci "{{test}}" {{args}}

ci-fast test="" *args:
  #!/usr/bin/env bash
  set -euo pipefail
  results=$(nix run nixpkgs#nix-eval-jobs -- \
    --flake ./templates/ci#tests{{if test != "" { "." + test } else { "" } }} \
    --override-input den . \
    --workers 4 \
    --force-recurse \
    --select 'tests: let
      go = prefix: v:
        if v ? expr then
          let
            hasExpected = v ? expected && !(v.expected ? undefined);
            hasExpectedError = v ? expectedError && !(v.expectedError ? undefined);
            pass = if hasExpected then v.expr == v.expected
                   else if hasExpectedError then true
                   else true;
            name = builtins.replaceStrings ["." "'\''"] ["-" "_"] prefix;
          in derivation {
            name = if pass then "PASS-${name}" else "FAIL-${name}";
            system = "{{system}}"; builder = "/bin/sh";
            args = ["-c" "echo > $out"];
          }
        else if builtins.isAttrs v then
          builtins.mapAttrs (k: go (if prefix == "" then k else "${prefix}.${k}")) v
        else derivation { name = "SKIP"; system = "{{system}}"; builder = "/bin/sh"; args = ["-c" "echo > $out"]; };
    in builtins.mapAttrs (k: go k) tests' \
    {{args}} 2>/dev/null)
  pass=$(echo "$results" | jq -r 'select(.name != null and (.name | startswith("PASS"))) | .name' | grep -c '^PASS' || true)
  fail_lines=$(echo "$results" | jq -r 'select(.name != null and (.name | startswith("FAIL"))) | .name' | grep '^FAIL' || true)
  fail=$(echo "$fail_lines" | grep -c '^FAIL' || true)
  errors=$(echo "$results" | jq -r 'select(.error != null) | .attr' || true)
  error_count=$(echo "$errors" | grep -c . || true)
  total=$((pass + fail + error_count))
  if [ -n "$fail_lines" ]; then
    echo "$fail_lines" | sed 's/^FAIL-/❌ /'
  fi
  if [ -n "$errors" ] && [ "$error_count" -gt 0 ]; then
    echo "$errors" | sed 's/^/💥 /'
  fi
  if [ "$fail" -eq 0 ] && [ "$error_count" -eq 0 ]; then
    echo "🎉 ${pass}/${total} successful"
  else
    echo "😢 ${pass}/${total} successful"
    exit 1
  fi

bogus *args:
  just nix-unit bogus "bogus" {{args}}

nix-unit template test *args:
  nix-unit  --override-input den . --flake ./templates/{{template}}#.tests.{{test}} {{args}}
  
check template *args:
  nix flake check  --override-input den . ./templates/{{template}} {{args}}

update template:
  nix flake update --flake ./templates/{{template}} den

all task:
  just {{task}} minimal
  just {{task}} example
  just {{task}} default
  just {{task}} ci
  just {{task}} bogus
  just {{task}} microvm
  just {{task}} nvf-standalone
  just {{task}} flake-parts-modules

fmt:
  nix run github:vic/checkmate#fmt --override-input target .

unit:
  nix flake check --override-input target . github:vic/checkmate

repl:
  nix repl --override-input den . ./templates/ci

[arg("tmpdir",long="tmpdir"), arg("head",long="head",short="h"), arg("base",long="base",short="b"), arg("warm",long="warm",short="w"), arg("runs",long="runs",short="r")]
bench tmpdir="/tmp" head="HEAD" base="refs/remotes/origin/main" warm="2" runs="5" *args: 
  rm -rf "{{tmpdir}}/den-head" "{{tmpdir}}/den-base"
  git clone --local --depth 1 --revision "$(git rev-list -n1 {{head}})" .git "{{tmpdir}}/den-head" 2>/dev/null
  git clone --local --depth 1 --revision "$(git rev-list -n1 {{base}})" .git "{{tmpdir}}/den-base" 2>/dev/null
  rm -rf "{{tmpdir}}/den-base/templates/ci"
  cp -r "{{tmpdir}}/den-head/templates/ci" "{{tmpdir}}/den-base/templates/ci"
  pushd "{{tmpdir}}/den-base" && git add templates/ci && popd
  hyperfine -m "{{runs}}" -w "{{warm}}" {{args}} \
    -n head "nix-unit --override-input den {{tmpdir}}/den-head --flake {{tmpdir}}/den-head/templates/ci#.tests.performance 2>&1 | tail -1" \
    -n base "nix-unit --override-input den {{tmpdir}}/den-base --flake {{tmpdir}}/den-base/templates/ci#.tests.performance 2>&1 | tail -1"
  rm -rf "{{tmpdir}}/den-head" "{{tmpdir}}/den-base"
