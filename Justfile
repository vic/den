help:
  just -l

check-all:
  just all check

update-all:
  just all update

docs:
  cd docs && pnpm run dev

ci test="":
  just nix-unit ci "{{test}}"

bogus:
  just nix-unit bogus ""

nix-unit template test:
  nix-unit  --override-input den . --flake ./templates/{{template}}#.tests.systems.x86_64-linux.system-agnostic.{{test}}
  
check template:
  nix flake check  --override-input den . ./templates/{{template}}

update template:
  nix flake update --flake ./templates/{{template}} den flake-aspects

all task:
  just {{task}} minimal
  just {{task}} example
  just {{task}} default
  just {{task}} ci
  just {{task}} bogus
  just {{task}} microvm

fmt:
  nix run github:vic/checkmate#fmt --override-input target .
