# typed: false
# frozen_string_literal: true

# rmoriedata -- dataset snapshots for the MORIE R packages, shipped as CSV with
# data dictionaries so examples and tests run without a network.
#
# The package is installed into this formula's keg under lib/R/<R x.y>/site-library,
# which `brew link` exposes in Homebrew R's site library
# ($(brew --prefix)/lib/R/<R x.y>/site-library), so `library(rmoriedata)` works in
# Homebrew's R. Dependencies already in that library are reused. After a minor R
# upgrade (for example 4.6 to 4.7), run `brew reinstall rmoriedata`.
# The `url` pins the signed release tag's archive so brew has a stable,
# checksummed download; livecheck tracks the live r-universe version.
class Rmoriedata < Formula
  desc "Offline snapshots of public datasets for the rmorie R package"
  homepage "https://rootcoder007.github.io/rmoriedata/"
  url "https://github.com/rootcoder007/rmoriedata/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "f592eab88741bde98398bfe533a4ae491927d062bdbcbb0e0d5b94996058bd96"
  license "AGPL-3.0-or-later"
  head "https://github.com/rootcoder007/rmoriedata.git", branch: "main"

  livecheck do
    url "https://rootcoder007.r-universe.dev/api/packages/rmoriedata"
    strategy :json do |json|
      json["Version"]
    end
  end

  depends_on "r"
  depends_on "rootcoder007/morie/rmoriebricklayer"

  # A copy of rmoriedata that install.packages() put in Homebrew R's site library (any R x.y)
  # is replaced when this formula links, instead of failing the link; files that belong
  # to another formula's keg are never touched. Same mechanism as python@3.x and pip.
  link_overwrite "lib/R/*/site-library/rmoriedata/*"

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
      siblings <- c("#{formula_opt_lib("rootcoder007/morie/rmoriebricklayer")/r_site_library}")
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
      got <- tryCatch(packageDescription("rmoriedata", lib.loc = keg)$Version, error = function(e) NA)
      if (!identical(got, "#{version}")) stop("rmoriedata #{version} did not install into the keg (found: ", got, ")")
    R
    system formula_opt_bin("r")/"R", "--vanilla", "--no-echo", "-f", buildpath/"install.R"
  end

  def caveats
    <<~EOS
      rmoriedata is linked into Homebrew R's site library:
        #{HOMEBREW_PREFIX}/lib/R/#{Formula["r"].version.major_minor}/site-library
      A copy installed there earlier with install.packages() is replaced by this one.
      After a minor R upgrade (for example 4.6 to 4.7), run `brew reinstall rmoriedata`.
    EOS
  end

  test do
    (testpath/"smoke.R").write <<~R
      library(rmoriedata)
      cat("rmoriedata", as.character(packageVersion("rmoriedata")), "OK\\n")
    R
    assert_match "rmoriedata #{version} OK", shell_output("#{formula_opt_bin("r")}/Rscript --vanilla #{testpath}/smoke.R")
  end
end
