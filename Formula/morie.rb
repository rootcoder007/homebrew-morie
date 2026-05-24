class Morie < Formula
  include Language::Python::Virtualenv

  desc "Multi-domain scientific computing toolkit with the MRM framework"
  homepage "https://hadesllm.github.io/morie/"
  url "https://files.pythonhosted.org/packages/f2/35/7f2e4b1b410be3f641351a7c5e88157996917a8240e06dddcd62be4857e9/morie-0.9.5.4.tar.gz"
  sha256 "b33e1a117a1909286510955d587e17a5c3b6de1f25c519ae1b6c2e0b9285b7ee"
  license "AGPL-3.0-or-later"

  # Live PyPI version probe. Without this, `brew livecheck` falls back
  # to the formula's `url` field -- which means brew can only ever say
  # "you're current" relative to whatever is committed in this file,
  # never relative to what is actually published on PyPI. With the
  # JSON strategy, `brew outdated morie` correctly flags new versions
  # the moment they land on pypi.org/project/morie, independent of
  # how stale this formula file might be.
  livecheck do
    url "https://pypi.org/pypi/morie/json"
    strategy :json do |json|
      json.dig("info", "version")
    end
  end

  depends_on "python@3.12"

  # Heavy runtime dependencies are resolved by pip at install time inside
  # the venv. This is the documented pattern for Python applications that
  # depend on the SciPy stack -- fully pinning resources here would mean
  # tracking ~30+ wheels through every numpy/pandas point release.
  #
  # We invoke `python -m pip` (not `pip` directly) because Homebrew's
  # virtualenv_create writes a pip launcher whose shebang can point at a
  # path that doesn't yet exist when pip runs from the formula sandbox,
  # silently failing the install.  `python -m pip` uses the venv's
  # python directly and resolves morie's declared dependencies
  # (numpy / pandas / scipy / scikit-learn / statsmodels / DoubleML /
  # matplotlib / httpx / ...) from PyPI.
  #
  # `--no-binary=ast_serialize` forces a source build of the
  # ast_serialize wheel, which otherwise ships with an install_name
  # load command too short for Homebrew's path rewriter to relink
  # (the symptom is "Failed changing dylib ID of
  # .../ast_serialize.abi3.so" / "needs to be relinked, possibly
  # with -headerpad_max_install_names" during install). Source
  # builds compile with fresh, correctly-padded load commands so
  # brew's install_name_tool patch succeeds first try.
  def install
    virtualenv_create(libexec, "python3.12")
    system libexec/"bin/python", "-m", "pip", "install", "--upgrade", "pip"
    system libexec/"bin/python", "-m", "pip", "install",
           "--no-binary=ast_serialize",
           "morie==#{version}"
    bin.install_symlink libexec/"bin/morie"
  end

  test do
    system bin/"morie", "--version"
    output = shell_output("#{libexec}/bin/python -c 'import morie; print(morie.__version__)'")
    assert_match version.to_s, output
  end
end
