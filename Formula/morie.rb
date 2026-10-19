class Morie < Formula
  include Language::Python::Virtualenv

  desc "Multi-domain scientific computing toolkit with the MRM framework"
  homepage "https://rootcoder007.github.io/morie/"
  url "https://files.pythonhosted.org/packages/27/b9/2e7f7f5bc7f92dea327a74af45158c6c039b58ce0f97d7bccce380a486a9/morie-1.5.0.tar.gz"
  sha256 "885ba7ada79278bc8e07dd858e895a89ee69c715bd9ad107cc8e564ea82d8471"
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

  # A `morie` launcher that `pip install morie` wrote into Homebrew's bin is replaced when
  # this formula links, instead of failing the link (as python@3.x does for pip).
  link_overwrite "bin/morie"

  # Runtime dependencies are resolved by pip at install time inside the
  # venv. morie's core needs only a few pure-Python packages (httpx, rich,
  # openpyxl, beautifulsoup4); numerical kernels are built in, with no NumPy
  # or pandas dependency.
  #
  # We invoke `python -m pip` (not `pip` directly) because Homebrew's
  # virtualenv_create writes a pip launcher whose shebang can point at a
  # path that doesn't yet exist when pip runs from the formula sandbox,
  # silently failing the install.  `python -m pip` uses the venv's
  # python directly and resolves morie's declared dependencies from PyPI.
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
