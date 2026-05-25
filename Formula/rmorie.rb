# typed: false
# frozen_string_literal: true

# rmorie -- R-only lite version of MORIE.
#
# This formula installs the rmorie R package into the system R library
# via `R CMD INSTALL`. Requires r-base to be installed first (declared
# as a hard dependency).
#
# Source comes from r-universe rather than CRAN because rmorie is not
# yet on CRAN -- the r-universe build is the authoritative binary.
class Rmorie < Formula
  desc "MORIE Toolkit (R-only lite version, CRAN+rOpenSci focused)"
  homepage "https://github.com/rootcoder007/rmorie"
  url "https://github.com/rootcoder007/rmorie/archive/refs/tags/v0.9.5.12.tar.gz"
  version "0.9.5.12"
  sha256 :no_check # filled in when the first tag lands; remove on first release
  license "AGPL-3.0-or-later"
  head "https://github.com/rootcoder007/rmorie.git", branch: "main"

  livecheck do
    url "https://api.github.com/repos/rootcoder007/rmorie/releases/latest"
    strategy :json do |json|
      json["tag_name"]&.delete_prefix("v")
    end
  end

  # System libraries the C++ backend links against.
  depends_on "libsodium"
  depends_on "openssl@3"
  depends_on "r"

  def install
    # Build the source tarball + install into R's site-library.
    system "R", "CMD", "build", ".", "--no-build-vignettes", "--no-manual"
    tarball = Dir["rmorie_*.tar.gz"].first
    odie "no tarball produced" unless tarball

    # Install into R's user-library (don't touch system R library).
    r_user_lib = `R RHOME`.chomp + "/site-library"
    ENV["R_LIBS_USER"] = r_user_lib
    mkdir_p r_user_lib

    system "R", "CMD", "INSTALL",
           "--library=#{r_user_lib}",
           "--no-test-load",
           "--no-help",
           tarball
  end

  test do
    # Smoke-load the package and call a simple exported function.
    (testpath/"smoke.R").write <<~R
      library(rmorie)
      stopifnot(is.character(packageVersion("rmorie")) ||
                is.numeric_version(packageVersion("rmorie")))
      cat("rmorie", as.character(packageVersion("rmorie")), "OK\\n")
    R
    system "R", "--vanilla", "--no-echo", "-f", testpath/"smoke.R"
  end
end
