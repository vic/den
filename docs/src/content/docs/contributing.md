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

The documentation website is under `./docs/`. Please help correct mistakes by sending a PR!

First, clone your fork of the repository.

```
$ git clone 'https://github.com/<your-username>/den'
$ cd den
```

Next, enter a nix shell.
```
## Classic tooling
$ nix-shell -p just nodejs pnpm
## or flakes tooling!
$ nix shell 'nixpkgs#just nixpkgs#nodejs nixpkgs#pnpm'
```

Then, change to the docs directory and install the necessary dependencies to `docs/node_modules`.

```
$ cd docs
$ pnpm install
```

Finally, start the docs webserver.

```
$ just docs
```

Now, you can edit the `.mdx` files in `docs/src/content/docs` and see your changes reflected immediately.


### Helping other people

One of the best forms of contribution does not even require submitting code. Hang out in our community
channels and help others with onboarding to den!

Thanks, You are awesome!

