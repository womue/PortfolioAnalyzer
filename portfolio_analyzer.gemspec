# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'portfolio_analyzer/version'

Gem::Specification.new do |spec|
  spec.name = "portfolio_analyzer"
  spec.version = PortfolioAnalyzer::VERSION
  spec.authors = ["Wolfgang Mueller"]
  spec.email = ["mueller@md-phw.de"]

  spec.summary = "Functionalities for analyzing e-portfolios"
  spec.description = "A toolset for analyizing Mahara-based e-portfolios"
  spec.homepage = 'https://github.com/womue/PortfolioAnalyzer'
  spec.license = 'Apache'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  # spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files = ["lib/portfolio_analyzer.rb", "lib/portfolio_analyzer/html_to_plain_text.rb",
                "lib/portfolio_analyzer/jsonable.rb", "lib/portfolio_analyzer/logging.rb",
                "lib/portfolio_analyzer/mahara_accessor.rb", "lib/portfolio_analyzer/mahara_member.rb",
                "lib/portfolio_analyzer/portfolio_analyzer_tools.rb", "lib/portfolio_analyzer/portfolio_statistics.rb",
                "lib/portfolio_analyzer/portfolio_view.rb", "lib/portfolio_analyzer/version.rb"
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
