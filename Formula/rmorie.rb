# typed: false
# frozen_string_literal: true

# rmorie -- the MORIE statistical toolkit for R, with a command line inside the
# package (rmorie::install_cli()). rmorie is not on CRAN; it and its
# r-universe-only dependencies install from r-universe.
#
# The package is installed into this formula's keg under lib/R/<R x.y>/site-library,
# which `brew link` exposes in Homebrew R's site library
# ($(brew --prefix)/lib/R/<R x.y>/site-library), so `library(rmorie)` works in
# Homebrew's R. Dependencies already in that library are reused. After a minor R
# upgrade (for example 4.6 to 4.7), run `brew reinstall rmorie`.
# The `url` pins the signed release tag's archive so brew has a stable,
# checksummed download; livecheck tracks the live r-universe version.
class Rmorie < Formula
  desc "Observational inference in R: causal effects, surveys, space-time models"
  homepage "https://rootcoder007.github.io/rmorie/"
  url "https://github.com/rootcoder007/rmorie/archive/refs/tags/v1.4.4.tar.gz"
  sha256 "de187a26dbbbc98a1cf2785efd353773ea091e080a00b85c388e8e92467c9a41"
  license "AGPL-3.0-or-later"
  head "https://github.com/rootcoder007/rmorie.git", branch: "main"

  livecheck do
    url "https://rootcoder007.r-universe.dev/api/packages/rmorie"
    strategy :json do |json|
      json["Version"]
    end
  end

  depends_on "curl"
  depends_on "libsodium"
  depends_on "r"
  depends_on "rootcoder007/morie/rmoriebricklayer"
  depends_on "rootcoder007/morie/rmoriedata"

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
      siblings <- c("#{formula_opt_lib("rootcoder007/morie/rmoriebricklayer")/r_site_library}", "#{formula_opt_lib("rootcoder007/morie/rmoriedata")/r_site_library}")
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
      got <- tryCatch(packageDescription("rmorie", lib.loc = keg)$Version, error = function(e) NA)
      if (!identical(got, "#{version}")) stop("rmorie #{version} did not install into the keg (found: ", got, ")")
    R
    system formula_opt_bin("r")/"R", "--vanilla", "--no-echo", "-f", buildpath/"install.R"
  end

  def caveats
    <<~EOS
      rmorie is linked into Homebrew R's site library:
        #{HOMEBREW_PREFIX}/lib/R/#{Formula["r"].version.major_minor}/site-library
      If rmorie was installed there before with install.packages(), `brew link`
      reports a conflict. Remove the old copy first, in Homebrew's R:
        remove.packages("rmorie")
      or let Homebrew replace it:
        brew link --overwrite rmorie
    EOS
  end

  test do
    (testpath/"smoke.R").write <<~R
      library(rmorie)
      cat("rmorie", as.character(packageVersion("rmorie")), "OK\\n")
    R
    assert_match "rmorie #{version} OK", shell_output("#{formula_opt_bin("r")}/Rscript --vanilla #{testpath}/smoke.R")
  end
end
