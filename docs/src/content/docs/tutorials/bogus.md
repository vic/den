---
title: "Template: Bug Reproduction"
description: Create minimal reproductions for Den bug reports using nix-unit.
---

The bogus template helps you create minimal bug reproductions. Use it when reporting issues or contributing fixes.

## Initialize

```console
mkdir bogus && cd bogus
nix flake init -t github:vic/den#bogus
nix flake update den
```

## Project Structure

```
flake.nix
modules/
  bug.nix           # your bug reproduction
  test-base.nix     # test infrastructure (DO NOT EDIT)
```

## Writing a Bug Reproduction

Edit `modules/bug.nix` with a minimal test case:

```nix
{ denTest, ... }:
{
  flake.tests.bogus = {
    test-something = denTest (
      { den, lib, igloo, tuxHm, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        # set up the scenario
        den.aspects.igloo.nixos.something = true;

        # what you get
        expr = igloo.something;
        # what you expect
        expected = true;
      }
    );
  };
}
```

### How denTest Works

`denTest` is a helper that:
1. Creates a fresh Den evaluation with your module
2. Provides helpers like `igloo` (host config), `tuxHm` (user's HM config)
3. Compares `expr` against `expected` using [nix-unit](https://github.com/nix-community/nix-unit)

Available test helpers (from `test-base.nix`):

| Helper | Description |
|--------|-------------|
| `igloo` | `nixosConfigurations.igloo.config` |
| `iceberg` | `nixosConfigurations.iceberg.config` |
| `tuxHm` | `igloo.home-manager.users.tux` |
| `pinguHm` | `igloo.home-manager.users.pingu` |
| `funnyNames` | Resolves an aspect for class `"funny"` and collects `.names` |
| `show` | `builtins.trace` helper for debugging |

## Run Tests

```console
nix flake check
```

## Testing Against Different Den Versions

Edit `.github/workflows/test.yml` to test against multiple Den versions:

```yaml
strategy:
  matrix:
    rev: ["main", "v1.0.0", "abc1234"]
```

This helps identify regressions — include `"main"` and any release tag or commit.

## Contributing a Fix

If you're submitting a fix to Den, test against your local checkout:

```console
cd <den-working-copy>
nix flake check --override-input den . ./templates/bogus
```

## What It Provides

| Feature | Provided |
|---------|:--------:|
| nix-unit test infrastructure | ✓ |
| Pre-configured denTest helper | ✓ |
| Version matrix testing | ✓ |
| Common test helpers | ✓ |

## Next Steps

- Share your reproduction repo on [GitHub Discussions](https://github.com/vic/den/discussions)
- Read [Debug Configurations](/guides/debug/) for debugging techniques
- See the [CI Tests template](/tutorials/ci/) for Den's own comprehensive test suite
