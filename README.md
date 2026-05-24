# homebrew-morie

Homebrew tap for [morie](https://hadesllm.github.io/morie/) — Multi-domain
Open Research and Inferential Estimation.

## Install

```sh
brew tap hadesllm/morie
brew install morie
```

## Upgrade

```sh
brew update
brew upgrade morie
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
| One-liner (no pip/python needed) | `curl -fsSL https://hadesllm.github.io/morie/install.sh \| bash` |
| PyPI | `pip install morie` |
| r-universe (R) | `install.packages('morie', repos='https://hadesllm.r-universe.dev')` |
| Docker (GHCR) | `docker run --rm ghcr.io/hadesllm/morie:latest morie --help` |

## See also

- **Main repo**: [`hadesllm/morie`](https://github.com/hadesllm/morie) — Python + R source, JSS papers, install.sh
- **Docs site**: [hadesllm.github.io/morie](https://hadesllm.github.io/morie/) — Sphinx-rendered reference, quick start, methods
- **PyPI**: [pypi.org/project/morie](https://pypi.org/project/morie/) — the upstream source distribution this formula pulls from
- **r-universe**: [hadesllm.r-universe.dev/morie](https://hadesllm.r-universe.dev/morie) — R-package nightly binary builds

## Pre-alpha (v0.x)

morie is in pre-alpha. The first alpha milestone is v1.0.0; everything below is point releases of pre-alpha code. APIs and findings may shift between minor versions. See the [main repo's papers/](https://github.com/hadesllm/morie/tree/main/papers) for the empirical work behind each release.

## Homebrew-core roadmap (post-v1.0.0)

This tap is the canonical install channel through the v0.x pre-alpha
window. After v1.0.0 ships on PyPI we'll attempt to upstream the
formula to **`homebrew-core`** so users can drop the tap step entirely
(`brew install morie`, no `brew tap` first, no `hadesllm/morie/morie`
in the upgrade-banner display).

The submission pipeline when v1.0.0 lands:

1. Tag `v1.0.0` on the main morie repo + push to PyPI.
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
