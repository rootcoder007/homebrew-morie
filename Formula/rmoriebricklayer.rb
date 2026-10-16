# typed: false
# frozen_string_literal: true

# rmoriebricklayer -- reproducible data capsules for R. Its C++17 core is the
# fetch layer for the MORIE packages and links libcurl and zlib.
#
# The package is installed into this formula's keg under lib/R/<R x.y>/site-library,
# which `brew link` exposes in Homebrew R's site library
# ($(brew --prefix)/lib/R/<R x.y>/site-library), so `library(rmoriebricklayer)` works in
# Homebrew's R. Dependencies already in that library are reused. After a minor R
# upgrade (for example 4.6 to 4.7), run `brew reinstall rmoriebricklayer`.
# The `url` pins the signed release tag's archive so brew has a stable,
# checksummed download; livecheck tracks the live r-universe version.
class Rmoriebricklayer < Formula
  desc "Reproducible data capsules for R with SHA-256 provenance and fallback"
  homepage "https://rootcoder007.github.io/rmorie-bricklayer/"
  url "https://github.com/rootcoder007/rmorie-bricklayer/archive/refs/tags/v0.5.14.tar.gz"
  sha256 "cd9a00540797c0497dfe8034e0d3d404ce2b34dc3b89d8047959c6d17c487ecf"
  license "AGPL-3.0-only"
  head "https://github.com/rootcoder007/rmorie-bricklayer.git", branch: "main"

  livecheck do
    url "https://rootcoder007.r-universe.dev/api/packages/rmoriebricklayer"
    strategy :json do |json|
      json["Version"]
    end
  end

  depends_on "curl"
  depends_on "r"

  uses_from_macos "zlib"

  def r_site_library
    "R/#{Formula["r"].version.major_minor}/site-library"
  end

  def install
    keg_lib = lib/r_site_library
    keg_lib.mkpath
    # Build the release source that Homebrew downloaded and checksummed. Sibling MORIE
    # packages come from their own formulas' kegs; any CRAN package still missing is
    # installed into this keg first.
    (buildpath/"install.R").write <<~R
      options(timeout = max(3600, getOption("timeout")))
      keg <- "#{keg_lib}"
      shared <- "#{HOMEBREW_PREFIX/"lib"/r_site_library}"
      siblings <- character()
      .libPaths(c(keg, siblings[dir.exists(siblings)], if (dir.exists(shared)) shared))
      desc <- read.dcf("DESCRIPTION")
      fields <- intersect(c("Depends", "Imports", "LinkingTo"), colnames(desc))
      wanted <- unlist(strsplit(gsub("[(][^)]*[)]", "", desc[1, fields]), "[,[:space:]]+"))
      wanted <- setdiff(wanted[nzchar(wanted)], c("R", rownames(installed.packages(priority = "base"))))
      missing <- setdiff(wanted, rownames(installed.packages(lib.loc = .libPaths())))
      if (length(missing)) {
        install.packages(missing, repos = "https://cloud.r-project.org", lib = keg,
                         dependencies = c("Depends", "Imports", "LinkingTo"))
      }
      install.packages(".", repos = NULL, type = "source", lib = keg)
      got <- tryCatch(packageDescription("rmoriebricklayer", lib.loc = keg)$Version, error = function(e) NA)
      if (!identical(got, "#{version}")) stop("rmoriebricklayer #{version} did not install into the keg (found: ", got, ")")
    R
    system formula_opt_bin("r")/"R", "--vanilla", "--no-echo", "-f", buildpath/"install.R"
  end

  def caveats
    <<~EOS
      rmoriebricklayer is linked into Homebrew R's site library:
        #{HOMEBREW_PREFIX}/lib/R/#{Formula["r"].version.major_minor}/site-library
      If rmoriebricklayer was installed there before with install.packages(), `brew link`
      reports a conflict. Remove the old copy first, in Homebrew's R:
        remove.packages("rmoriebricklayer")
      or let Homebrew replace it:
        brew link --overwrite rmoriebricklayer
    EOS
  end

  test do
    (testpath/"smoke.R").write <<~R
      library(rmoriebricklayer)
      cat("rmoriebricklayer", as.character(packageVersion("rmoriebricklayer")), "OK\\n")
    R
    assert_match "rmoriebricklayer #{version} OK", shell_output("#{formula_opt_bin("r")}/Rscript --vanilla #{testpath}/smoke.R")
  end
end
