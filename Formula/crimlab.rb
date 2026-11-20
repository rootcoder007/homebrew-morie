# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Homebrew formula (macOS and Linux), also in the tap rootcoder007/crimlab:
#   brew install rootcoder007/morie/crimlab
# Builds the crimlab command from the release's source tarball. tap.yml
# sets url and sha256 for each published release; `brew install --HEAD`
# builds main.
class Crimlab < Formula
  desc "Statistical toolkit for criminology and sociolegal research"
  homepage "https://crimlab.dev/"
  url "https://github.com/rootcoder007/crimlab/releases/download/v0.0.3/crimlab-0.0.3.tar.gz"
  sha256 "0aeb53b4d01460daf55771a916fcd25f5711c8b19421aca2fa14f07d3fd99bdc"
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/rootcoder007/crimlab.git", branch: "main"

  def install
    system "make", "-C", "cli", "crimlab", "CXX=#{ENV.cxx}", "CXXFLAGS=-O2", "WERROR="
    system "make", "-C", "cli", "check"
    bin.install "cli/crimlab"
    man1.install "cli/crimlab.1"
  end

  test do
    assert_match "0.1475205", shell_output("#{bin}/crimlab orrisk --or 2 --rate 0.1 --share 0.3")
    assert_match "\"nfail\":0", shell_output("#{bin}/crimlab selftest -j")
  end
end
