# -*- encoding: utf-8 -*-

require File.expand_path('../lib/google_maps_tools/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "google-maps-tools"
  s.version = GoogleMapsTools::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["J Smith"]
  s.description = "Google Maps tools."
  s.summary = s.description
  s.email = "dark.panda@gmail.com"
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "https://github.com/dark-panda/google-maps-tools"
  s.require_paths = ["lib"]

  s.add_dependency("activesupport", [">= 2.3"])
end

