# typed: false
# frozen_string_literal: true

# rmorie -- R-only version of MORIE.
#
# Installs the rmorie R package -- and its full dependency tree -- into R's
# site-library via `install.packages()` from r-universe. rmorie is not on CRAN,
# and its hard deps include the r-universe-only rmoriebricklayer (Imports +
# LinkingTo) and rmoriedata; install.packages from r-universe resolves the whole
# graph (CRAN deps + r-universe deps) in one shot. Requires r (declared below).
#
# The `url` pins an immutable github commit archive so brew has a stable,
# checksummed download; livecheck tracks the live r-universe version since rmorie
# publishes no GitHub releases/tags.
class Rmorie < Formula
  desc "MORIE Toolkit (R-only version, CRAN+rOpenSci focused)"
  homepage "https://github.com/rootcoder007/rmorie"
  url "https://github.com/rootcoder007/rmorie/archive/83bba959d30ca80623e55092f1cc3eea7f9c3171.tar.gz"
  version "0.9.9"
  sha256 "82b2625bf5576afd53464937814694eeeff678e758161cfad749109ff704a37f"
  license "AGPL-3.0-or-later"
  head "https://github.com/rootcoder007/rmorie.git", branch: "main"

  livecheck do
    url "https://rootcoder007.r-universe.dev/api/packages/rmorie"
    strategy :json do |json|
      json["Version"]
    end
  end

  # System libraries the C++ backend links against.
  depends_on "libsodium"
  depends_on "openssl@3"
  depends_on "r"

  def install
    # Resolve + install rmorie and its full dependency tree from r-universe
    # (CRAN deps like Rcpp/RcppArmadillo AND the r-universe-only
    # rmoriebricklayer / rmoriedata) into R's site-library, so a user's
    # `library(rmorie)` works. r-universe serves a prebuilt binary on macOS.
    site_lib = `R RHOME`.chomp + "/site-library"
    ENV["R_LIBS_USER"] = site_lib
    mkdir_p site_lib
    (buildpath/"install.R").write <<~R
      install.packages(
        "rmorie",
        repos = c("https://rootcoder007.r-universe.dev",
                  "https://cloud.r-project.org"),
        lib  = "#{site_lib}",
        dependencies = c("Depends", "Imports", "LinkingTo")
      )
      if (!requireNamespace("rmorie", lib.loc = "#{site_lib}", quietly = TRUE)) {
        stop("rmorie failed to install")
      }
    R
    system "R", "--vanilla", "--no-echo", "-f", buildpath/"install.R"
  end

  test do
    # Smoke-load the package and confirm the version is reported.
    (testpath/"smoke.R").write <<~R
      library(rmorie)
      stopifnot(is.character(packageVersion("rmorie")) ||
                is.numeric_version(packageVersion("rmorie")))
      cat("rmorie", as.character(packageVersion("rmorie")), "OK\\n")
    R
    system "R", "--vanilla", "--no-echo", "-f", testpath/"smoke.R"
  end
end
