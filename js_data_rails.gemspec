Gem::Specification.new do |s|
  s.name         = "js_data_rails"
  s.version      = "0.1"
  s.license      = "MIT"
  s.authors      = ["Ed Saunders"]
  s.email        = ["ed@twistilled.com"]
  s.homepage     = "http://twistilled.com"
  s.summary      = "An interface to turn js-data queries and Rails queries"
  s.description  = "This interface allows users to query a Rails backend using js-data-formatted queries, and then converts this into ActiveRecord style 'where' clauses"

  s.add_dependency "rails", "~> 4.1"

  s.add_development_dependency "rspec", "~> 3.3"
  s.add_development_dependency "pry", "~> 0.10.1"

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^spec/})
  s.require_paths = ["lib"]
end
