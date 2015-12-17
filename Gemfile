source 'https://rubygems.org'

gem 'rails', '4.1.4'

gem 'sqlite3'

gem 'sass-rails', '~> 5.0.4'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer',  platforms: :ruby

gem 'jquery-rails'
# gem 'js-routes'

gem 'versionist'
gem 'graphql'
gem 'graphql-relay'

gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0',          group: :doc

gem 'spring',        group: :development

gem 'foundation-rails', '~> 5.5.3.2'
gem 'react-rails', '~> 1.5.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :production do
  gem 'unicorn'
  gem 'pg'
end

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

group :development do
  gem 'thin'
  gem 'quiet_assets'
  gem 'capistrano', '~> 2.15'
end

group :developemnt, :test do
  gem 'spring-commands-rspec'
  gem 'rspec-rails'
  gem 'guard-rspec'
  gem 'capybara'
  gem 'fabrication'
  gem 'rb-fsevent' if `uname` =~ /Darwin/
end