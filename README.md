# homebrew-morie

Homebrew tap for [morie](https://rootcoder007.github.io/morie/) — Multi-domain
Open Research and Inferential Estimation.

## Install

```sh
brew tap rootcoder007/morie
brew trust rootcoder007/morie            # Homebrew 6.0+ only (see note)
brew install morie                       # full Python+R toolkit
brew install rmorie                      # R-only lite version
```

> **The `brew trust` step is expected — not a warning about morie.** Since
> Homebrew 6.0, *every* third-party tap is untrusted by default — including
> major vendors like `mongodb/brew`, `heroku/brew`, and `hashicorp/tap`.
> Homebrew trusts only formulae in `homebrew-core`; being outside it says
> nothing about a tap's legitimacy. `brew trust` records your one-time consent
> in `~/.homebrew/trust.json` (per machine — it cannot be set globally by a tap
> author). On Homebrew ≤ 5.x there is no trust step; just `brew install`.
> Once morie lands in `homebrew-core` (roadmap below) the tap and trust steps
> disappear entirely.

## Upgrade

```sh
brew update
brew upgrade rootcoder007/morie/morie
```

## What you get

- The `morie` CLI on your PATH.
- A self-contained Python 3.12 virtualenv at
  `$(brew --prefix)/opt/morie/libexec` with the full scientific stack
  (pandas, numpy, scipy, scikit-learn, statsmodels, DoubleML).
- Pure-Python install — no compilers required on your machine.

## Alternatives

| Channel | Command |
| --- | --- |
| One-liner (no pip/python needed) | `curl -fsSL https://rootcoder007.github.io/morie/install.sh \| bash` |
| PyPI | `pip install morie` |
| r-universe (R) | `install.packages('morie', repos='https://rootcoder007.r-universe.dev')` |
| Docker (GHCR) | `docker run --rm ghcr.io/rootcoder007/morie:latest morie --help` |

## See also

- **Main repo**: [`rootcoder007/morie`](https://github.com/rootcoder007/morie) — Python + R source, JSS papers, install.sh
- **Docs site**: [rootcoder007.github.io/morie](https://rootcoder007.github.io/morie/) — Sphinx-rendered reference, quick start, methods
- **PyPI**: [pypi.org/project/morie](https://pypi.org/project/morie/) — the upstream source distribution this formula pulls from
- **r-universe**: [rootcoder007.r-universe.dev/morie](https://rootcoder007.r-universe.dev/morie) — R-package nightly binary builds

## Release status

morie is a stable 1.x release (1.1.6 on PyPI). As active research software, empirical findings and some APIs may still evolve between minor versions — see the [main repo's papers/](https://github.com/rootcoder007/morie/tree/main/papers) for the work behind each release.

## Homebrew-core roadmap

morie is past 1.0.0 (1.1.6 live on PyPI), so it already clears
homebrew-core's stable-release bar. This tap is the canonical channel
today; the plan is to upstream the formula to **`homebrew-core`** so
users can drop the tap step entirely (`brew install morie`, no
`brew tap` first, no `brew trust`).

The submission pipeline:

1. Confirm the current `vX.Y.Z` tag on the main morie repo is on PyPI.
2. Generate the explicit Python `resource` blocks via
   `brew update-python-resources --print-only morie`
   (or [`homebrew-pypi-poet`](https://github.com/tdsmith/homebrew-pypi-poet)
   if the built-in tool misses transitive chains).
3. Replace this tap's pip-at-install-time block with
   `virtualenv_install_with_resources` (the core-required helper
   that uses the explicit resources instead of dynamic pip resolution).
4. Local audit: `brew audit --new-formula morie` +
   `HOMEBREW_NO_INSTALL_FROM_API=1 brew install --build-from-source morie`.
5. `brew bump-formula-pr --new-formula morie` -> Homebrew/homebrew-core PR.

**Acceptance frame**: homebrew-core rejects Python/R libraries that
are primarily importable. morie's submission has to be framed around
the standalone `morie` CLI (data audits, pipeline tasks, synthetic
data generation), not the import-from-Python angle. AGPL is accepted
but reviewed closely for dependency-license compliance, so every
generated `resource` block needs an OSI-compatible upstream license.

Until homebrew-core lands, this tap remains the supported channel.

## License

Tap definition: AGPL-3.0-or-later.
morie itself: AGPL-3.0-or-later (Python and R). The optional Linux-kernel
adjuncts in the main repo's `kernel-module/` and `daemon/` stay GPL-2.0-only
(kernel ABI requirement) and are not part of the Homebrew install. Papers,
data, and documentation are CC BY-NC-SA 4.0.
