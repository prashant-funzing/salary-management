# Optional built-in Ruby coverage; no additional runtime dependency.
require "coverage"
Coverage.start(lines: true, branches: true)
at_exit do
  require "json"
  require "fileutils"
  files = Coverage.result.filter_map do |path, coverage|
    next unless path.start_with?(File.expand_path("../app/", __dir__) + "/")
    lines = coverage[:lines].compact
    branches = coverage[:branches].values.flat_map(&:values)
    [ path.delete_prefix(File.expand_path("../", __dir__) + "/"), {
      lines_covered: lines.count(&:positive?), lines_total: lines.size,
      branches_covered: branches.count(&:positive?), branches_total: branches.size
    } ]
  end.to_h
  FileUtils.mkdir_p(File.expand_path("../tmp", __dir__))
  File.write(File.expand_path("../tmp/test-coverage.json", __dir__), JSON.pretty_generate(files))
  puts "Coverage written to tmp/test-coverage.json (loaded application files only)."
end
