# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{activeconfig}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeremy Lawler"]
  s.date = %q{2009-04-11}
  s.default_executable = %q{active_config}
  s.email = %q{jlawler@cashnetusa.com}
  s.executables = ["active_config"]
  s.files = [
    "Rakefile",
    "VERSION.yml",
    "bin/active_config",
    "lib/active_config.rb",
    "lib/active_config/hash_config.rb",
    "lib/active_config/hash_weave.rb",
    "lib/active_config/suffixes.rb",
    "lib/cnu_config.rb",
    "test/active_config_test.rb",
    "test/active_config_test/global.yml",
    "test/active_config_test/test.yml",
    "test/active_config_test/test_GB.yml",
    "test/active_config_test/test_US.yml",
    "test/active_config_test/test_config.yml",
    "test/active_config_test/test_local.yml",
    "test/active_config_test/test_production.yml",
    "test/active_config_test_multi.rb",
    "test/active_config_test_multi/patha/test.yml",
    "test/active_config_test_multi/pathb/test_local.yml",
    "test/cnu_config_test.rb",
    "test/cnu_config_test/global.yml",
    "test/cnu_config_test/test.yml",
    "test/cnu_config_test/test_GB.yml",
    "test/cnu_config_test/test_US.yml",
    "test/cnu_config_test/test_local.yml",
    "test/env_test.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://jlawler.github.com/activeconfig/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{An extremely flexible configuration system}
  s.test_files = [
    "test/cnu_config_test.rb",
    "test/active_config_test.rb",
    "test/active_config_test_multi.rb",
    "test/env_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
