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

  s.add_dependency "rails", "~> 6.1"
  s.add_dependency "responders"
  s.add_dependency "acts_as_tree"
  s.add_dependency "acts_as_list"

  s.add_dependency "active_model_serializers"
  s.add_dependency "api-pagination"

  s.add_dependency "settingslogic"
  s.add_dependency "request_store"

  s.add_dependency "devise", "4.7.3"
  s.add_dependency "devise-security", "0.15.0"
  s.add_dependency "devise_zxcvbn"
  s.add_dependency "cancancan"

  s.add_dependency "kaminari"
  s.add_dependency "haml"
  s.add_dependency "haml_coffee_assets"

  s.add_dependency "paperclip"
  s.add_dependency "paperclip-av-transcoder"
  s.add_dependency "video_info"
  s.add_dependency "friendly_mime"

  s.add_dependency "geocoder"
  s.add_dependency "icalendar"
  s.add_dependency "chronic"
  s.add_dependency "tod", "3.1"
  s.add_dependency "date_validator"
  s.add_dependency "uuidtools"
  s.add_dependency "signed_json"

  s.add_dependency "vcard"
  s.add_dependency "rdiscount"

  s.add_dependency "searchkick"
  s.add_dependency "elasticsearch"
  s.add_dependency "yomu"
  s.add_dependency "typhoeus"

  s.add_dependency "mail_form"
  s.add_dependency "mustache"

  s.add_dependency "gibbon"

  s.add_development_dependency "mysql2"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "ruby-prof"
end
