# Bug Reproduction den

READ: https://den.oeiuwq.com/tutorials/ci/

Use this small template to reproduce bugs in den.

Edit the `rev` list being tested at [`test.yml`](.github/workflows/test.yml), include `"main"` and any other release tag or commit sha you might want to test. This is useful for showing regressions.

Create a **minimal** bug reproduction at [`modules/bug.nix`](modules/bug.nix)

Each `denTest` is isolated from others so you can create as many
as you want with same hosts and users.

Then run tests:

```shell
nix flake check
```

Running a single test with `nixpkgs#nix-unit` on PATH:

```shell
# append any attrName to run just particular tests
nix-unit --flake .#.tests.systems.x86_64-linux.system-agnostic
```

Please share a link to your reproduction repo, showing the CI step and the error at CI build.

## Fixing Den

If you are contributing a bug-fix PR, you can use the following command to
use your local den checkout.

```shell
nix-unit  --override-input den <den-working-copy>  --flake <your-bogus-repo>#.tests.systems.x86_64-linux.system-agnostic
```
