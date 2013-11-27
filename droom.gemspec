$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "droom/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "droom"
  s.version     = Droom::VERSION
  s.authors     = ["William Ross"]
  s.email       = ["will@spanner.org"]
  s.homepage    = "http://droom.spanner.org"
  s.summary     = "Droom is your new data room."
  s.description = "Droom is nice and clean."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.0.0"
  s.add_dependency "jquery-rails"

  s.add_dependency "devise", "~> 3.0.0"
  s.add_dependency "devise-encryptable"
  s.add_dependency "coca", "~> 0.4.0"
  s.add_dependency "cancan"
  s.add_dependency "msg", "~> 0.4.0"

  s.add_dependency "acts_as_tree"
  s.add_dependency "acts_as_list"
  s.add_dependency "kaminari"
  s.add_dependency "haml"

  s.add_dependency "paperclip"
  s.add_dependency "fog"

  s.add_dependency "geocoder"
  s.add_dependency "icalendar"
  s.add_dependency "chronic"
  s.add_dependency "time_of_day"
  s.add_dependency "date_validator"
  s.add_dependency "uuidtools"

  s.add_dependency "snail"
  s.add_dependency "vcard"
  s.add_dependency "rdiscount"
  s.add_dependency "yomu"
  s.add_dependency "youtube_it"
  s.add_dependency "dropbox-sdk"
  
  s.add_development_dependency "mysql2"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "ruby-prof"
end
