# Bug Reproduction den

Use this small template to reproduce bugs in den.

Create a **minimal** bug reproduction at [`modules/bug.nix`](modules/bug.nix)

See also [Den debugging tips](https://den.oeiuwq.com/debugging.html)

Then run tests:

```shell
nix flake check
```

Please share a link to your reproduction repo, showing the CI step and the
error at CI build.

## Fixing Den

If you are contributing a bug-fix PR, you can use the following command to
use your local den checkout.

```shell
cd <den-working-copy>
nix flake check --override-input den . ./templates/bogus
```
