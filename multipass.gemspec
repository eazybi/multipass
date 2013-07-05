# encoding: utf-8

Gem::Specification.new do |s|
  s.name = "multipass"
  s.version = "1.3.2"

  s.authors = ["Raimonds Simanovskis"]
  s.date = "2013-07-05"
  s.email = ["raimonds.simanovskis@gmail.com"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README"
  ]
  s.files = [
    "LICENSE",
    "README",
    "Rakefile",
    "VERSION.yml",
    "lib/multipass.rb",
    "multipass.gemspec",
    "test/multipass_test.rb"
  ]
  s.homepage = "https://github.com/eazybi/multipass"
  s.require_paths = ["lib"]
  s.summary = "Bare bones implementation of encoding and decoding MultiPass values for SSO."

  s.add_runtime_dependency "ezcrypto"
  s.add_runtime_dependency "json"

end
