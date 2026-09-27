# Fork notes

This is a personal fork of [basecamp/omarchy](https://github.com/basecamp/omarchy),
forked from the `master` branch at **v3.8.5** (`f4378f0d`).

## Why this fork is pinned to 3.8.x

Upstream **deleted the `master` branch** after releasing Omarchy 4 ("quattro").
Upstream's default branch is now `quattro`, and Omarchy 4 is a completely
different install model: instead of a git checkout in `~/.local/share/omarchy`,
it ships as two pacman packages (`omarchy`, `omarchy-settings`) installed to
`/usr/share/omarchy`, built from PKGBUILDs in the separate `omarchy-pkgs` repo.

That means there is no upstream 3.8.x line left to merge from. This fork is the
maintained line for this machine. Upstream changes can still be cherry-picked
from the `upstream` remote, but they target the v4 layout and will rarely apply
cleanly.

## Remotes

| Remote | Points at | Used for |
| --- | --- | --- |
| `origin` | `sam-mceachern/omarchy` | `omarchy-update` pulls from here |
| `upstream` | `basecamp/omarchy` | reference, cherry-picking |

`omarchy-update-git` runs `git pull --autostash` against `origin/master`, so
anything pushed to this fork's `master` arrives via the normal `omarchy update`.

## Changes from upstream

- `bin/omarchy-reinstall-git` — re-clones from this fork
- `bin/omarchy-update-confirm` — "What's new" links to this fork's releases
- `boot.sh` — `OMARCHY_REPO` defaults to this fork, so a fresh install from
  this fork's `boot.sh` bootstraps from here

## What this fork does NOT control

- **Binary packages.** `default/pacman/mirrorlist-*` still points at
  `stable-mirror.omarchy.org`. Omarchy's own packages (`omarchy-chromium`, the
  themed fonts, etc.) still come from Basecamp's repo. Hosting your own would
  mean building and signing your own pacman repo.
- **Package lists on an existing system.** `omarchy-update` only runs
  `pacman -Syyu`. The lists in `install/omarchy-base.packages` and
  `install/omarchy-other.packages` are read only by a fresh install
  (`install/packaging/base.sh`) and by `omarchy-reinstall-pkgs`. Editing a list
  does not install anything here — use `omarchy-pkg-add <pkg>` for that, and
  edit the list so *new* installs from this fork get it too.
- **`omarchy-upgrade-to-quattro`** is broken upstream-side: it fetches
  `master.tar.gz` from basecamp/omarchy, which no longer exists.

## Working on this fork

```bash
cd ~/.local/share/omarchy
# edit bin/, themes/, default/, config/, install/*.packages
git add -A && git commit -m "..."
git push
```

Changes to `bin/` are live immediately (it is on `PATH` via `OMARCHY_PATH`).
Changes to `default/` and `config/` are *defaults* — they seed `~/.config` and
are read by refresh commands; they do not retroactively rewrite files already in
your home directory.
