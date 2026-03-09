---
title: Contributing
description: Report bugs and contribute pull-requests
---

All contributions welcome. PRs are checked by CI.

### Run tasks

Use `just help` to get a list of all tasks.

```console
just fmt
just ci
```

### Bug Reports

Use the `bogus` template to create a minimal reproduction:

```console
mkdir bogus && cd bogus
nix flake init -t github:vic/den#bogus
nix flake update den
nix flake check
```

Share your repository with us on [Discussions](https://github.com/vic/den/discussions).

Or even better, send a PR with a failing test, both the bogus template and CI use the same test helpers.

Failing tests are an awesome way to improve Den. Thanks :)

### Contributing Documentation

If you have found some dead link or spelling/grammatical errors, please help by sending a PR.

The documentation website is under `./docs/`, You can run it locally with: `pnpm run dev`.


### Helping other people

One of the best forms of contribution does not even involves PR. Hang out in our community
channels and help others getting aboard. Helping others is the best way to contribute.

Thanks, You are awesome! 

