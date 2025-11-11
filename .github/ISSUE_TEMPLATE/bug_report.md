---

name: Bug report
about: Issues are testable/actionable tasks. Use Discussions for questions, feature-requests, problem solving.
title: 'BUG: '
labels: 'bug'
assignees: ''

---

If you have found a bug, please share a reproduction repository with us.

First step is to clone the `bogus` template and edit `modules/bug.nix`.

```console
nix flake init -t github:vic/den#bogus
nix flake update den
vim modules/bug.nix
nix flake check
```

Your repository will help us verify that we can reproduce the bug in a minimal environment - Your repo has CI actions enabled. When the bug has been fixed we can use your same code as a non-regression test to ensure bugs do not appear again.

### Description

Provide a very small description of the intended and the actual behaviour.

Share a link to a [discussion](https://github.com/vic/den/discussions) to keep track of it.
