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

fmt:
  nix run github:vic/checkmate#fmt --override-input target .

unit:
  nix flake check --override-input target . github:vic/checkmate

[arg("tmpdir",long="tmpdir"), arg("head",long="head",short="h"), arg("base",long="base",short="b"), arg("warm",long="warm",short="w"), arg("runs",long="runs",short="r")]
bench tmpdir="/tmp" head="HEAD" base="refs/remotes/origin/main" warm="2" runs="5" *args: 
  rm -rf "{{tmpdir}}/den-head" "{{tmpdir}}/den-base"
  git clone --local --depth 1 --revision "$(git rev-list -n1 {{head}})" .git "{{tmpdir}}/den-head" 2>/dev/null
  git clone --local --depth 1 --revision "$(git rev-list -n1 {{base}})" .git "{{tmpdir}}/den-base" 2>/dev/null
  hyperfine -m "{{runs}}" -w "{{warm}}" {{args}} \
    -n head "cd {{tmpdir}}/den-head && nix-shell ./shell.nix --run 'just ci 2>&1 | grep successful'" \
    -n base "cd {{tmpdir}}/den-base && nix-shell ./shell.nix --run 'just ci 2>&1 | grep successful'" 
  rm -rf "{{tmpdir}}/den-head" "{{tmpdir}}/den-base"
