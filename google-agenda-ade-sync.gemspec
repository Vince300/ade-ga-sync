# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'google/agenda/ade/sync/version'

Gem::Specification.new do |spec|
  spec.name          = "google-agenda-ade-sync"
  spec.version       = Google::Agenda::Ade::Sync::VERSION
  spec.authors       = ["Vincent Tavernier"]
  spec.email         = ["vincent.tavernier@ensimag.grenoble-inp.fr"]

  spec.summary       = %q{google-agenda-ade-sync is a synchronization tool between Google Agenda and Ensimag ADE}
  spec.homepage      = "https://github.com/Vince300/ade-ga-sync"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "" # No push URL
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "codecov"
  spec.add_development_dependency "codeclimate-test-reporter"

  spec.add_runtime_dependency 'icalendar', '~>2.3.0'
  spec.add_runtime_dependency 'trollop', '~>2.1.2'
  spec.add_runtime_dependency 'google-api-client', '0.8.6'

  spec.add_runtime_dependency 'tzinfo-data'
end
