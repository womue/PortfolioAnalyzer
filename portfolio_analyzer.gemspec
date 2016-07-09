Gem::Specification.new do |s|
  s.name = 'portfolio_analyzer'
  s.version = '0.0.0'
  s.date = '2016-07-08'
  s.summary = "Functionalities for analyzing e-portfolios"
  s.description = "A toolset for analyizing Mahara-based e-portfolios"
  s.authors = ["Wolfgang Mueller, Sandra Rebholz, Paul Libbrecht"]
  s.email = 'mueller@md-phw.de'
  s.files = ["lib/portfolio_analyzer.rb", "lib/portfolio_analyzer/html_to_plain_text.rb",
             "lib/portfolio_analyzer/jsonable.rb", "lib/portfolio_analyzer/logging.rb",
             "lib/portfolio_analyzer/mahara_accessor.rb", "lib/portfolio_analyzer/mahara_member.rb",
             "lib/portfolio_analyzer/portfolio_analyzer_tools.rb", "lib/portfolio_analyzer/portfolio_statistics.rb",
             "lib/portfolio_analyzer/portfolio_view.rb"
  ]
  s.homepage =
      'https://github.com/womue/PortfolioAnalyzer'
  s.license = 'Apache'
end