help:
  just -l

check-all:
  nix-build ./templates/noflake --no-out-link -A flake.nixosConfigurations.igloo
  just all check
  just unit

update-all:
  cd templates/noflake && npins update den flake-aspects
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

unit:
  nix flake check --override-input target . github:vic/checkmate
